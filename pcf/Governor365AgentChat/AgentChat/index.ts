import { IInputs, IOutputs } from "./generated/ManifestTypes";
import { AgentChatView } from "./AgentChat";
import { CanvasActionEnvelope } from "./protocol";
import * as React from "react";

export class AgentChat implements ComponentFramework.ReactControl<IInputs, IOutputs> {
    private notifyOutputChanged!: () => void;
    private context!: ComponentFramework.Context<IInputs>;
    private connectionStatus = "disconnected";
    private conversationId = "";
    private lastActionName = "";
    private lastActionJson = "";
    private lastError = "";
    private readonly fallbackUserId = `canvas-${crypto.randomUUID()}`;

    /**
     * Empty constructor.
     */
    constructor() {
        // Empty
    }

    /**
     * Used to initialize the control instance. Controls can kick off remote server calls and other initialization actions here.
     * Data-set values are not initialized here, use updateView.
     * @param context The entire property bag available to control via Context Object; It contains values as set up by the customizer mapped to property names defined in the manifest, as well as utility functions.
     * @param notifyOutputChanged A callback method to alert the framework that the control has new outputs ready to be retrieved asynchronously.
     * @param state A piece of data that persists in one session for a single user. Can be set at any point in a controls life cycle by calling 'setControlState' in the Mode interface.
     */
    public init(
        context: ComponentFramework.Context<IInputs>,
        notifyOutputChanged: () => void,
        state: ComponentFramework.Dictionary
    ): void {
        this.context = context;
        this.notifyOutputChanged = notifyOutputChanged;
        context.mode.trackContainerResize(true);
    }

    /**
     * Called when any value in the property bag has changed. This includes field values, data-sets, global values such as container height and width, offline status, control metadata values such as label, visible, etc.
     * @param context The entire property bag available to control via Context Object; It contains values as set up by the customizer mapped to names defined in the manifest, as well as utility functions
     * @returns ReactElement root react element for the control
     */
    public updateView(context: ComponentFramework.Context<IInputs>): React.ReactElement {
        this.context = context;

        return React.createElement(AgentChatView, {
            contextJson: context.parameters.contextJson.raw,
            contextVersion: context.parameters.contextVersion.raw ?? 0,
            locale: nonEmptyOrDefault(context.parameters.locale.raw, "en-US"),
            onAgentAction: this.handleAgentAction,
            onStatusChanged: this.handleStatusChanged,
            promptText: context.parameters.promptText.raw,
            promptVersion: context.parameters.promptVersion.raw ?? 0,
            ssoClientId: context.parameters.ssoClientId.raw,
            ssoLoginHint: context.parameters.ssoLoginHint.raw,
            ssoRedirectUri: context.parameters.ssoRedirectUri.raw,
            ssoTenantId: context.parameters.ssoTenantId.raw,
            title: nonEmptyOrDefault(context.parameters.title.raw, "Governor365"),
            tokenEndpoint: context.parameters.tokenEndpoint.raw ?? "",
            userDisplayName: nonEmptyOrDefault(context.parameters.userDisplayName.raw, "Power Apps user"),
            userId: nonEmptyOrDefault(context.parameters.userId.raw, this.fallbackUserId)
        });
    }

    /**
     * It is called by the framework prior to a control receiving new data.
     * @returns an object based on nomenclature defined in manifest, expecting object[s] for property marked as "bound" or "output"
     */
    public getOutputs(): IOutputs {
        return {
            connectionStatus: this.connectionStatus,
            conversationId: this.conversationId,
            lastActionJson: this.lastActionJson,
            lastActionName: this.lastActionName,
            lastError: this.lastError
        };
    }

    /**
     * Called when the control is to be removed from the DOM tree. Controls should use this call for cleanup.
     * i.e. cancelling any pending remote calls, removing listeners, etc.
     */
    public destroy(): void {
        // The published player can call destroy during initial composition while
        // retaining the rendered control. Page teardown releases the transport.
    }

    private readonly handleStatusChanged = (status: string, conversationId: string, error: string): void => {
        const changed =
            status !== this.connectionStatus ||
            conversationId !== this.conversationId ||
            error !== this.lastError;

        if (!changed) {
            return;
        }

        this.connectionStatus = status;
        this.conversationId = conversationId;
        this.lastError = error;

        if (status === "error") {
            this.notifyOutputChanged();
            this.context.events.OnConnectionStatusChanged();
        }
    };

    private readonly handleAgentAction = (action: CanvasActionEnvelope): void => {
        this.lastActionName = action.name;
        this.lastActionJson = JSON.stringify(action);
        this.notifyOutputChanged();
        this.context.events.OnAgentAction();
    };
}

function nonEmptyOrDefault(value: string | null | undefined, fallback: string): string {
    const normalized = value?.trim();
    return normalized?.length ? normalized : fallback;
}
