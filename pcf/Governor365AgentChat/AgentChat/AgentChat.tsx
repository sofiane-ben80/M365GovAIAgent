import * as React from "react";
import {
    Activity as DirectLineActivity,
    ConnectionStatus,
    DirectLine
} from "botframework-directlinejs";
import type { DirectLineCardAction } from "botframework-webchat-core";
import { ReactWebChat, createStore } from "botframework-webchat";
import {
    CANVAS_ACTION_ACTIVITY_NAME,
    CanvasActionEnvelope,
    JsonValue,
    START_CONVERSATION_ACTIVITY_NAME,
    createContextEnvelope,
    getDirectLineUserId,
    getTokenEndpointDetails,
    parseCanvasAction,
    parseContext,
    parseContextPrompt,
    parseOAuthCardTokenExchange,
    parsePrompt
} from "./protocol";
import { SsoTokenProvider } from "./sso";

interface ConversationTokenResponse {
    token?: string;
    conversationId?: string;
}

interface RegionalChannelSettingsResponse {
    channelUrlsById?: {
        directline?: string;
    };
}

interface AgentChatProps {
    tokenEndpoint: string;
    contextJson?: string | null;
    contextVersion: number;
    promptText?: string | null;
    promptVersion: number;
    ssoClientId?: string | null;
    ssoTenantId?: string | null;
    ssoRedirectUri?: string | null;
    ssoLoginHint?: string | null;
    userId: string;
    userDisplayName: string;
    locale: string;
    title: string;
    onStatusChanged: (status: string, conversationId: string, error: string) => void;
    onAgentAction: (action: CanvasActionEnvelope) => void;
}

interface Activity {
    channelData?: Record<string, unknown>;
    from?: {
        id?: string;
        name?: string;
        role?: string;
    };
    id?: string;
    locale?: string;
    name?: string;
    text?: string;
    type?: string;
    value?: unknown;
}

interface ReduxAction {
    payload?: unknown;
    type?: string;
}

type DirectLineClient = DirectLine;
interface CardActionArguments {
    cardAction: DirectLineCardAction;
    getSignInUrl?: () => string;
    target: unknown;
}
type CardActionResult = Record<string, never>;
type CardActionMiddleware = () => (
    next: (args: CardActionArguments) => CardActionResult
) => (args: CardActionArguments) => CardActionResult;

const DEFAULT_SSO_CLIENT_ID = "f104fe0a-6b8a-446b-a623-cfbd7c7e2b11";
const DEFAULT_SSO_TENANT_ID = "8221c52a-2c7f-4da0-8b1f-34c6f692d915";
const DEFAULT_SSO_REDIRECT_URI = "https://runtime-app.powerplatform.com/";

function configuredValue(value: string | null | undefined, fallback: string): string {
    const normalized = value?.trim();
    return normalized?.length ? normalized : fallback;
}

const styleOptions = {
    accent: "#60A5FA",
    backgroundColor: "#1E293B",
    botAvatarBackgroundColor: "#334155",
    botAvatarInitials: "G",
    bubbleBackground: "#334155",
    bubbleBorderRadius: 8,
    bubbleFromUserBackground: "#1D4ED8",
    bubbleFromUserBorderRadius: 8,
    bubbleFromUserTextColor: "#FFFFFF",
    bubbleTextColor: "#F8FAFC",
    disableFileUpload: true,
    primaryFont: "'Segoe UI', sans-serif",
    sendBoxBackground: "#0F172A",
    sendBoxButtonColor: "#60A5FA",
    sendBoxTextColor: "#F8FAFC",
    sendBoxPlaceholder: "Ask Governor365",
    suggestedActionBackgroundColor: "#334155",
    suggestedActionBorderColor: "#60A5FA",
    suggestedActionTextColor: "#BFDBFE"
};

export const AgentChatView: React.FC<AgentChatProps> = props => {
    const [directLine, setDirectLine] = React.useState<DirectLineClient>();
    const [store, setStore] = React.useState<ReturnType<typeof createStore>>();
    const [cardActionMiddleware, setCardActionMiddleware] = React.useState<CardActionMiddleware>();
    const [error, setError] = React.useState("");
    const contextRef = React.useRef<JsonValue>({});
    const contextVersionRef = React.useRef<number>(-1);
    const directLineUserIdRef = React.useRef("");
    const handledCanvasActionIdsRef = React.useRef<Set<string>>(new Set());
    const receivedActivityIdsRef = React.useRef<Set<string>>(new Set());
    const promptVersionRef = React.useRef<number>(-1);

    React.useEffect(() => {
        let disposed = false;
        let closeDirectLine: (() => void) | undefined;
        let activitySubscription: { unsubscribe(): void } | undefined;
        let connectionStatusSubscription: { unsubscribe(): void } | undefined;

        const connect = async (): Promise<void> => {
            setError("");
            setDirectLine(undefined);
            setStore(undefined);
            setCardActionMiddleware(undefined);
            props.onStatusChanged("connecting", "", "");

            try {
                const endpointDetails = getTokenEndpointDetails(props.tokenEndpoint);
                const context = parseContext(props.contextJson);
                const prompt = parsePrompt(props.promptText);
                const contextPrompt = parseContextPrompt(context);
                contextRef.current = context;
                contextVersionRef.current = props.contextVersion;
                promptVersionRef.current =
                    props.promptVersion > 0 && prompt
                        ? props.promptVersion
                        : contextPrompt?.version ?? props.promptVersion;

                const [settings, conversation] = await Promise.all([
                    fetchJson<RegionalChannelSettingsResponse>(endpointDetails.regionalSettingsEndpoint),
                    fetchJson<ConversationTokenResponse>(endpointDetails.tokenEndpoint)
                ]);

                if (!settings.channelUrlsById?.directline) {
                    throw new Error("Copilot Studio did not return a regional Direct Line URL.");
                }

                if (!conversation.token) {
                    throw new Error("Copilot Studio did not return a Direct Line token.");
                }

                const directLineUserId = getDirectLineUserId(conversation.token);
                const ssoTokenProvider = createSsoTokenProvider(props);
                let latestTokenExchange:
                    | { connectionName: string; id: string; uri: string }
                    | undefined;

                if (disposed) {
                    return;
                }

                directLineUserIdRef.current = directLineUserId;
                handledCanvasActionIdsRef.current.clear();
                receivedActivityIdsRef.current.clear();
                const domain = `${settings.channelUrlsById.directline.replace(/\/+$/, "")}/v3/directline`;
                const activeDirectLine = new DirectLine({
                    domain,
                    pollingInterval: 1000,
                    token: conversation.token,
                    webSocket: false
                });
                const endDirectLine = activeDirectLine.end.bind(activeDirectLine);

                // Web Chat can transiently disconnect while the Canvas host retains this control.
                // Keep the shared polling transport alive until this effect is actually disposed.
                activeDirectLine.end = () => undefined;
                closeDirectLine = endDirectLine;

                const chatStore = createStore(
                    {},
                    ({ dispatch }) => next => action => {
                        const typedAction = action as ReduxAction;
                        const incomingActivity =
                            typedAction.type === "DIRECT_LINE/INCOMING_ACTIVITY"
                                ? getActionActivity(typedAction.payload)
                                : undefined;

                        if (
                            incomingActivity?.id &&
                            receivedActivityIdsRef.current.has(incomingActivity.id)
                        ) {
                            return action;
                        }

                        if (incomingActivity?.id) {
                            rememberActivityId(receivedActivityIdsRef.current, incomingActivity.id);
                        }

                        const tokenExchange = parseOAuthCardTokenExchange(incomingActivity);

                        if (tokenExchange && ssoTokenProvider) {
                            latestTokenExchange = tokenExchange;
                            void exchangeSsoToken(
                                activeDirectLine,
                                directLineUserId,
                                props.userDisplayName,
                                ssoTokenProvider,
                                tokenExchange,
                                "silent",
                                () => next(action),
                                exchangeError => {
                                    const message = getErrorMessage(exchangeError);
                                    setError(message);
                                    props.onStatusChanged(
                                        "error",
                                        conversation.conversationId ?? "",
                                        message
                                    );
                                }
                            );

                            return action;
                        }

                        if (typedAction.type === "DIRECT_LINE/POST_ACTIVITY") {
                            const activity = getActionActivity(typedAction.payload);

                            if (activity?.type === "message") {
                                activity.channelData = {
                                    ...activity.channelData,
                                    governor365Context: createContextEnvelope(
                                        contextRef.current,
                                        contextVersionRef.current
                                    )
                                };
                            }
                        }

                        const result = next(action);

                        if (typedAction.type === "DIRECT_LINE/INCOMING_ACTIVITY") {
                            if (
                                incomingActivity?.type === "event" &&
                                incomingActivity.name === CANVAS_ACTION_ACTIVITY_NAME
                            ) {
                                const canvasAction = parseCanvasAction(incomingActivity.value);
                                const activityId = incomingActivity.id;

                                if (
                                    canvasAction &&
                                    (!activityId || !handledCanvasActionIdsRef.current.has(activityId))
                                ) {
                                    if (activityId) {
                                        handledCanvasActionIdsRef.current.add(activityId);
                                    }

                                    props.onAgentAction(canvasAction);
                                }
                            }
                        }

                        if (typedAction.type === "DIRECT_LINE/CONNECT_REJECTED") {
                            props.onStatusChanged(
                                "error",
                                conversation.conversationId ?? "",
                                getErrorMessage(typedAction.payload, "Direct Line rejected the connection.")
                            );
                        }

                        return result;
                    }
                );
                const interactiveSignInMiddleware: CardActionMiddleware = () => next => args => {
                    if (
                        isAuthenticationCardAction(args.cardAction) &&
                        ssoTokenProvider &&
                        latestTokenExchange
                    ) {
                        void exchangeSsoToken(
                            activeDirectLine,
                            directLineUserId,
                            props.userDisplayName,
                            ssoTokenProvider,
                            latestTokenExchange,
                            "interactive",
                            () => undefined,
                            exchangeError => {
                                const message = getErrorMessage(exchangeError);
                                setError(message);
                                props.onStatusChanged(
                                    "error",
                                    conversation.conversationId ?? "",
                                    message
                                );
                            }
                        );

                        return {};
                    }

                    return next(args);
                };

                // Keep HTTP polling alive when the published player recycles Web Chat subscriptions.
                activitySubscription = activeDirectLine.activity$.subscribe(activity => {
                    chatStore.dispatch({
                        type: "DIRECT_LINE/INCOMING_ACTIVITY",
                        payload: { activity }
                    });
                });

                let initialActivitiesSent = false;
                connectionStatusSubscription = activeDirectLine.connectionStatus$.subscribe(connectionStatus => {
                    if (connectionStatus !== ConnectionStatus.Online || initialActivitiesSent) {
                        return;
                    }

                    initialActivitiesSent = true;
                    const initialPrompt =
                        props.promptVersion > 0 && prompt
                            ? prompt
                            : contextPrompt?.text;

                    const initialActivity = initialPrompt
                        ? createCanvasPromptActivity(
                            props,
                            directLineUserId,
                            initialPrompt,
                            contextRef.current,
                            contextVersionRef.current
                        )
                        : createStartConversationActivity(props, directLineUserId, contextRef.current);

                    activeDirectLine.postActivity(initialActivity).subscribe({
                        error: postError => {
                            const message = getErrorMessage(postError);
                            setError(message);
                            props.onStatusChanged("error", conversation.conversationId ?? "", message);
                        }
                    });

                    props.onStatusChanged("connected", conversation.conversationId ?? "", "");
                });

                if (disposed) {
                    return;
                }

                setDirectLine(activeDirectLine);
                setStore(chatStore);
                setCardActionMiddleware(() => interactiveSignInMiddleware);
            } catch (caughtError) {
                if (!disposed) {
                    const message = getErrorMessage(caughtError);
                    setError(message);
                    props.onStatusChanged("error", "", message);
                }
            }
        };

        void connect();

        return () => {
            disposed = true;
            activitySubscription?.unsubscribe();
            connectionStatusSubscription?.unsubscribe();
            closeDirectLine?.();
        };
    }, [
        props.ssoClientId,
        props.ssoLoginHint,
        props.ssoRedirectUri,
        props.ssoTenantId,
        props.tokenEndpoint,
        props.userId
    ]);

    React.useEffect(() => {
        if (!directLine || !store || promptVersionRef.current === props.promptVersion) {
            return;
        }

        try {
            const prompt = parsePrompt(props.promptText);

            if (!prompt) {
                promptVersionRef.current = props.promptVersion;
                return;
            }

            promptVersionRef.current = props.promptVersion;
            directLine.postActivity(
                createCanvasPromptActivity(
                    props,
                    directLineUserIdRef.current,
                    prompt,
                    contextRef.current,
                    contextVersionRef.current
                )
            ).subscribe({
                error: postError => {
                    const message = getErrorMessage(postError);
                    setError(message);
                    props.onStatusChanged("error", "", message);
                }
            });
        } catch (caughtError) {
            const message = getErrorMessage(caughtError);
            setError(message);
            props.onStatusChanged("error", "", message);
        }
    }, [
        directLine,
        props.locale,
        props.onStatusChanged,
        props.promptText,
        props.promptVersion,
        props.userDisplayName,
        props.userId,
        store
    ]);

    React.useEffect(() => {
        if (!directLine || !store || contextVersionRef.current === props.contextVersion) {
            return;
        }

        try {
            const context = parseContext(props.contextJson);
            const contextPrompt = parseContextPrompt(context);
            contextRef.current = context;
            contextVersionRef.current = props.contextVersion;

            if (contextPrompt && contextPrompt.version !== promptVersionRef.current) {
                promptVersionRef.current = contextPrompt.version;
                directLine.postActivity(
                    createCanvasPromptActivity(
                        props,
                        directLineUserIdRef.current,
                        contextPrompt.text,
                        context,
                        props.contextVersion
                    )
                ).subscribe({
                    error: postError => {
                        const message = getErrorMessage(postError);
                        setError(message);
                        props.onStatusChanged("error", "", message);
                    }
                });
            }
        } catch (caughtError) {
            const message = getErrorMessage(caughtError);
            setError(message);
            props.onStatusChanged("error", "", message);
        }
    }, [
        directLine,
        props.contextJson,
        props.contextVersion,
        props.locale,
        props.onStatusChanged,
        props.userDisplayName,
        props.userId,
        store
    ]);

    if (directLine && store && typeof ReactWebChat !== "function") {
        const message = "The embedded Web Chat component failed to initialize.";

        return (
            <section className="governor365-agent-chat" aria-label={props.title}>
                <div className="governor365-agent-chat__status" role="alert">{message}</div>
            </section>
        );
    }

    return (
        <section className="governor365-agent-chat" aria-label={props.title}>
            <header className="governor365-agent-chat__header">
                <span className="governor365-agent-chat__presence" aria-hidden="true" />
                <h2>{props.title}</h2>
            </header>
            <div className="governor365-agent-chat__body">
                {directLine && store ? (
                    <ReactWebChat
                        cardActionMiddleware={
                            cardActionMiddleware ? [cardActionMiddleware] : undefined
                        }
                        directLine={directLine}
                        locale={props.locale}
                        store={store}
                        styleOptions={styleOptions}
                        userID={directLineUserIdRef.current}
                        username={props.userDisplayName}
                    />
                ) : (
                    <div className="governor365-agent-chat__status" role={error ? "alert" : "status"}>
                        {error || "Connecting to Governor365..."}
                    </div>
                )}
            </div>
        </section>
    );
};

function createSsoTokenProvider(props: AgentChatProps): SsoTokenProvider | undefined {
    const clientId = configuredValue(props.ssoClientId, DEFAULT_SSO_CLIENT_ID);
    const tenantId = configuredValue(props.ssoTenantId, DEFAULT_SSO_TENANT_ID);
    const redirectUri = configuredValue(props.ssoRedirectUri, DEFAULT_SSO_REDIRECT_URI);
    const configuredLoginHint = props.ssoLoginHint?.trim() ?? "";
    const loginHint = configuredLoginHint
        ? configuredLoginHint
        : props.userId.includes("@")
            ? props.userId
            : "";

    return new SsoTokenProvider({
        clientId,
        tenantId,
        redirectUri,
        loginHint
    });
}

function isAuthenticationCardAction(cardAction: unknown): boolean {
    if (typeof cardAction !== "object" || cardAction === null) {
        return false;
    }

    const candidate = cardAction as { title?: unknown; type?: unknown };
    return candidate.type === "signin" ||
        (typeof candidate.title === "string" &&
            candidate.title.trim().toLowerCase() === "login");
}

async function exchangeSsoToken(
    directLine: DirectLineClient,
    userId: string,
    userDisplayName: string,
    tokenProvider: SsoTokenProvider,
    tokenExchange: { connectionName: string; id: string; uri: string },
    mode: "silent" | "interactive",
    showOAuthCard: () => unknown,
    reportError: (error: unknown) => void
): Promise<void> {
    try {
        const token = mode === "interactive"
            ? await tokenProvider.acquireTokenInteractive(tokenExchange.uri)
            : await tokenProvider.acquireToken(tokenExchange.uri);

        if (!token) {
            showOAuthCard();
            return;
        }

        // Direct Line accepts invoke activities although this SDK version's Activity union omits them.
        const invokeActivity = {
            from: {
                id: userId,
                name: userDisplayName,
                role: "user"
            },
            name: "signin/tokenExchange",
            type: "invoke",
            value: {
                connectionName: tokenExchange.connectionName,
                id: tokenExchange.id,
                token
            }
        } as unknown as DirectLineActivity;

        directLine.postActivity(invokeActivity).subscribe({
            error: exchangeError => {
                reportError(exchangeError);
                showOAuthCard();
            },
            next: activityId => {
                if (activityId === "retry") {
                    showOAuthCard();
                }
            }
        });
    } catch (error) {
        reportError(error);
        showOAuthCard();
    }
}

function createCanvasPromptActivity(
    props: AgentChatProps,
    directLineUserId: string,
    prompt: string,
    context: JsonValue,
    contextVersion: number
): DirectLineActivity {
    return {
        channelData: {
            clientActivityID: crypto.randomUUID(),
            governor365Context: createContextEnvelope(context, contextVersion),
            governor365Source: "canvasCommand"
        },
        from: {
            id: directLineUserId,
            name: props.userDisplayName,
            role: "user"
        },
        locale: props.locale,
        text: prompt,
        type: "message"
    };
}

function createStartConversationActivity(
    props: AgentChatProps,
    directLineUserId: string,
    context: JsonValue
): DirectLineActivity {
    return {
        channelData: { postBack: true },
        from: {
            id: directLineUserId,
            name: props.userDisplayName,
            role: "user"
        },
        name: START_CONVERSATION_ACTIVITY_NAME,
        type: "event",
        value: createContextEnvelope(context, props.contextVersion)
    };
}

async function fetchJson<T>(url: string): Promise<T> {
    const response = await fetch(url, {
        headers: {
            Accept: "application/json"
        },
        method: "GET"
    });

    if (!response.ok) {
        throw new Error(`Copilot Studio request failed with HTTP ${response.status}.`);
    }

    return response.json() as Promise<T>;
}

function getActionActivity(payload: unknown): Activity | undefined {
    if (typeof payload !== "object" || payload === null || !("activity" in payload)) {
        return undefined;
    }

    return (payload as { activity?: Activity }).activity;
}

function rememberActivityId(activityIds: Set<string>, activityId: string): void {
    if (activityIds.size >= 1_000) {
        const oldestActivityId = activityIds.values().next().value;

        if (oldestActivityId) {
            activityIds.delete(oldestActivityId);
        }
    }

    activityIds.add(activityId);
}

function getErrorMessage(error: unknown, fallback = "The agent connection failed."): string {
    if (error instanceof Error && error.message.trim()) {
        return error.message;
    }

    if (
        typeof error === "object" &&
        error !== null &&
        "message" in error &&
        typeof error.message === "string" &&
        error.message.trim()
    ) {
        return error.message;
    }

    return fallback;
}
