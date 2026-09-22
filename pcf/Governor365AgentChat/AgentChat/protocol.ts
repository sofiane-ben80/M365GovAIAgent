export const CONTEXT_ACTIVITY_NAME = "governor365.context";
export const CANVAS_ACTION_ACTIVITY_NAME = "governor365.canvas.action";
export const START_CONVERSATION_ACTIVITY_NAME = "startConversation";
export const MAX_CONTEXT_LENGTH = 16_384;
export const MAX_ACTION_LENGTH = 16_384;
export const MAX_PROMPT_LENGTH = 4_000;

const ALLOWED_TOKEN_HOST_SUFFIXES = [
    ".environment.api.powerplatform.com",
    ".environment.api.powerplatform.us"
];

export type JsonValue =
    | boolean
    | number
    | string
    | null
    | JsonValue[]
    | { [key: string]: JsonValue };

export interface CanvasContextEnvelope {
    schemaVersion: "1.0";
    source: "Governor365.Canvas";
    sequence: number;
    sentAt: string;
    context: JsonValue;
}

export interface CanvasActionEnvelope {
    schemaVersion: "1.0";
    name: string;
    correlationId?: string;
    payload?: JsonValue;
}

export interface CanvasPrompt {
    text: string;
    version: number;
}

export interface OAuthCardTokenExchange {
    connectionName: string;
    id: string;
    uri: string;
}

export interface TokenEndpointDetails {
    tokenEndpoint: string;
    regionalSettingsEndpoint: string;
}

export function getTokenEndpointDetails(rawEndpoint: string): TokenEndpointDetails {
    const endpoint = new URL(rawEndpoint.trim());

    if (endpoint.protocol !== "https:") {
        throw new Error("The Copilot Studio token endpoint must use HTTPS.");
    }

    const hostAllowed = ALLOWED_TOKEN_HOST_SUFFIXES.some(
        suffix => endpoint.hostname.endsWith(suffix) || endpoint.hostname === suffix.slice(1)
    );

    if (!hostAllowed) {
        throw new Error("The token endpoint must be hosted by Power Platform.");
    }

    const pathMarker = "/powervirtualagents/";
    const markerIndex = endpoint.pathname.toLowerCase().indexOf(pathMarker);
    const apiVersion = endpoint.searchParams.get("api-version");

    if (markerIndex < 0 || !apiVersion) {
        throw new Error("The token endpoint is not a valid Copilot Studio Mobile App channel endpoint.");
    }

    const environmentBase = `${endpoint.origin}${endpoint.pathname.slice(0, markerIndex)}`;
    const regionalSettingsEndpoint =
        `${environmentBase}/powervirtualagents/regionalchannelsettings?api-version=${encodeURIComponent(apiVersion)}`;

    return {
        tokenEndpoint: endpoint.toString(),
        regionalSettingsEndpoint
    };
}

export function parseContext(contextJson: string | null | undefined): JsonValue {
    const normalized = contextJson?.trim();

    if (!normalized) {
        return {};
    }

    if (normalized.length > MAX_CONTEXT_LENGTH) {
        throw new Error(`Canvas context exceeds the ${MAX_CONTEXT_LENGTH}-character limit.`);
    }

    const parsed: unknown = JSON.parse(normalized);

    if (!isJsonValue(parsed) || typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
        throw new Error("Canvas context must be a JSON object.");
    }

    return parsed;
}

export function parsePrompt(promptText: string | null | undefined): string {
    const normalized = promptText?.trim() ?? "";

    if (normalized.length > MAX_PROMPT_LENGTH) {
        throw new Error(`Canvas prompt exceeds the ${MAX_PROMPT_LENGTH}-character limit.`);
    }

    return normalized;
}

export function parseContextPrompt(context: JsonValue): CanvasPrompt | undefined {
    if (typeof context !== "object" || context === null || Array.isArray(context)) {
        return undefined;
    }

    const version = context.canvasPromptVersion;
    const text = context.canvasPromptText;

    if (typeof version !== "number" || !Number.isSafeInteger(version) || version <= 0 || typeof text !== "string") {
        return undefined;
    }

    const prompt = parsePrompt(text);

    return prompt ? { text: prompt, version } : undefined;
}

export function getDirectLineUserId(token: string): string {
    const payload = token.split(".")[1];

    if (!payload) {
        throw new Error("Copilot Studio returned a malformed Direct Line token.");
    }

    try {
        const paddedPayload = payload.replace(/-/g, "+").replace(/_/g, "/")
            .padEnd(Math.ceil(payload.length / 4) * 4, "=");
        const claims: unknown = JSON.parse(atob(paddedPayload));

        if (
            typeof claims === "object" &&
            claims !== null &&
            "user" in claims &&
            typeof claims.user === "string" &&
            claims.user.trim()
        ) {
            return claims.user.trim();
        }
    } catch {
        throw new Error("Copilot Studio returned a malformed Direct Line token.");
    }

    throw new Error("The Direct Line token does not contain a user identity.");
}

export function createContextEnvelope(context: JsonValue, sequence: number): CanvasContextEnvelope {
    return {
        schemaVersion: "1.0",
        source: "Governor365.Canvas",
        sequence,
        sentAt: new Date().toISOString(),
        context
    };
}

export function parseCanvasAction(value: unknown): CanvasActionEnvelope | undefined {
    if (!isJsonValue(value) || typeof value !== "object" || value === null || Array.isArray(value)) {
        return undefined;
    }

    const candidate = value as Record<string, JsonValue>;

    if (candidate.schemaVersion !== "1.0" || typeof candidate.name !== "string" || !candidate.name.trim()) {
        return undefined;
    }

    const action: CanvasActionEnvelope = {
        schemaVersion: "1.0",
        name: candidate.name.trim()
    };

    if (typeof candidate.correlationId === "string") {
        action.correlationId = candidate.correlationId;
    }

    if (candidate.payload !== undefined) {
        action.payload = candidate.payload;
    }

    if (JSON.stringify(action).length > MAX_ACTION_LENGTH) {
        return undefined;
    }

    return action;
}

export function parseOAuthCardTokenExchange(activity: unknown): OAuthCardTokenExchange | undefined {
    if (!isRecord(activity) || !Array.isArray(activity.attachments) || activity.attachments.length === 0) {
        return undefined;
    }

    const attachment: unknown = activity.attachments[0];

    if (
        !isRecord(attachment) ||
        attachment.contentType !== "application/vnd.microsoft.card.oauth" ||
        !isRecord(attachment.content) ||
        typeof attachment.content.connectionName !== "string" ||
        !isRecord(attachment.content.tokenExchangeResource)
    ) {
        return undefined;
    }

    const resource = attachment.content.tokenExchangeResource;

    if (
        typeof resource.id !== "string" ||
        !resource.id.trim() ||
        typeof resource.uri !== "string" ||
        !resource.uri.trim()
    ) {
        return undefined;
    }

    return {
        connectionName: attachment.content.connectionName,
        id: resource.id,
        uri: resource.uri
    };
}

function isJsonValue(value: unknown): value is JsonValue {
    if (value === null || ["boolean", "number", "string"].includes(typeof value)) {
        return true;
    }

    if (Array.isArray(value)) {
        return value.every(isJsonValue);
    }

    if (typeof value === "object") {
        return Object.values(value).every(isJsonValue);
    }

    return false;
}

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}
