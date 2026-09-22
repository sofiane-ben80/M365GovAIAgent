const MSAL_SCRIPT_URL = "https://alcdn.msauth.net/browser/2.32.2/js/msal-browser.min.js";
let msalLoader: Promise<MsalNamespace> | undefined;

export interface SsoConfiguration {
    clientId: string;
    tenantId: string;
    redirectUri: string;
    loginHint: string;
}

interface MsalAccount {
    username: string;
}

interface MsalAuthenticationResult {
    accessToken: string;
}

interface MsalClient {
    acquireTokenSilent(request: { account: MsalAccount; scopes: string[] }): Promise<MsalAuthenticationResult>;
    acquireTokenPopup(request: {
        loginHint?: string;
        scopes: string[];
    }): Promise<MsalAuthenticationResult>;
    getAllAccounts(): MsalAccount[];
    handleRedirectPromise(): Promise<unknown>;
    ssoSilent(request: { loginHint: string; scopes: string[] }): Promise<MsalAuthenticationResult>;
}

interface MsalNamespace {
    PublicClientApplication: new (configuration: {
        auth: {
            authority: string;
            clientId: string;
            redirectUri: string;
        };
        cache: {
            cacheLocation: "sessionStorage";
            storeAuthStateInCookie: false;
        };
    }) => MsalClient;
}

export class SsoTokenProvider {
    private readonly configuration: SsoConfiguration;
    private client?: MsalClient;
    private initialization?: Promise<void>;

    public constructor(configuration: SsoConfiguration) {
        this.configuration = {
            clientId: requireGuid(configuration.clientId, "SSO client ID"),
            tenantId: requireGuid(configuration.tenantId, "SSO tenant ID"),
            redirectUri: requireHttpsUrl(configuration.redirectUri, "SSO redirect URI"),
            loginHint: configuration.loginHint.trim()
        };
    }

    public async acquireToken(resourceUri: string): Promise<string | undefined> {
        const scope = requireScope(resourceUri);
        await this.ensureInitialized();

        const client = this.client;

        if (!client) {
            throw new Error("Microsoft authentication failed to initialize.");
        }

        const account = this.findAccount(client);

        if (account) {
            try {
                const result = await client.acquireTokenSilent({
                    account,
                    scopes: [scope]
                });

                return result.accessToken;
            } catch (error) {
                if (!isInteractionRequired(error)) {
                    throw error;
                }
            }
        }

        if (!this.configuration.loginHint) {
            return undefined;
        }

        try {
            const result = await client.ssoSilent({
                loginHint: this.configuration.loginHint,
                scopes: [scope]
            });

            return result.accessToken;
        } catch (error) {
            if (isInteractionRequired(error)) {
                return undefined;
            }

            throw error;
        }
    }

    public async acquireTokenInteractive(resourceUri: string): Promise<string> {
        const scope = requireScope(resourceUri);
        await this.ensureInitialized();

        const client = this.client;

        if (!client) {
            throw new Error("Microsoft authentication failed to initialize.");
        }

        const result = await client.acquireTokenPopup({
            ...(this.configuration.loginHint
                ? { loginHint: this.configuration.loginHint }
                : {}),
            scopes: [scope]
        });

        return result.accessToken;
    }

    private async ensureInitialized(): Promise<void> {
        this.initialization ??= this.initialize();
        await this.initialization;
    }

    private async initialize(): Promise<void> {
        const msal = await loadMsal();
        this.client = new msal.PublicClientApplication({
            auth: {
                authority: `https://login.microsoftonline.com/${this.configuration.tenantId}`,
                clientId: this.configuration.clientId,
                redirectUri: this.configuration.redirectUri
            },
            cache: {
                cacheLocation: "sessionStorage",
                storeAuthStateInCookie: false
            }
        });
        await this.client.handleRedirectPromise();
    }

    private findAccount(client: MsalClient): MsalAccount | undefined {
        const accounts = client.getAllAccounts();

        if (!this.configuration.loginHint) {
            return accounts[0];
        }

        const normalizedHint = this.configuration.loginHint.toLowerCase();
        return accounts.find(account => account.username.toLowerCase() === normalizedHint) ?? accounts[0];
    }
}

function loadMsal(): Promise<MsalNamespace> {
    const existing = getMsal();

    if (existing) {
        return Promise.resolve(existing);
    }

    msalLoader ??= new Promise<MsalNamespace>((resolve, reject) => {
        const script = document.createElement("script");
        script.async = true;
        script.src = MSAL_SCRIPT_URL;
        script.addEventListener("load", () => {
            const loaded = getMsal();

            if (loaded) {
                resolve(loaded);
            } else {
                reject(new Error("Microsoft authentication library did not initialize."));
            }
        }, { once: true });
        script.addEventListener(
            "error",
            () => reject(new Error("Microsoft authentication library could not be loaded.")),
            { once: true }
        );
        document.head.appendChild(script);
    });

    return msalLoader;
}

function getMsal(): MsalNamespace | undefined {
    return (globalThis as typeof globalThis & { msal?: MsalNamespace }).msal;
}

function isInteractionRequired(error: unknown): boolean {
    if (typeof error !== "object" || error === null || !("errorCode" in error)) {
        return false;
    }

    const errorCode = String(error.errorCode).toLowerCase();
    return [
        "interaction_required",
        "login_required",
        "consent_required",
        "monitor_window_timeout"
    ].includes(errorCode);
}

function requireGuid(value: string, name: string): string {
    const normalized = value.trim();

    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(normalized)) {
        throw new Error(`${name} must be a valid GUID.`);
    }

    return normalized;
}

function requireHttpsUrl(value: string, name: string): string {
    const normalized = value.trim();
    const url = new URL(normalized);

    if (url.protocol !== "https:") {
        throw new Error(`${name} must use HTTPS.`);
    }

    return url.toString();
}

function requireScope(value: string): string {
    const normalized = value.trim();

    if (!/^api:\/\/[0-9a-f-]+\/[A-Za-z0-9._-]+$/i.test(normalized)) {
        throw new Error("Copilot Studio returned an invalid token-exchange resource.");
    }

    return normalized;
}
