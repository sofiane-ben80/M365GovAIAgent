import { strict as assert } from "node:assert";
import { test } from "node:test";
import { SsoTokenProvider } from "./sso";

void test("interactive sign-in requests the token-exchange scope with the configured login hint", async () => {
    const requests: { loginHint?: string; scopes: string[] }[] = [];

    class InteractionRequiredError extends Error {
        public readonly errorCode = "interaction_required";
    }

    class FakePublicClientApplication {
        public acquireTokenPopup(request: { loginHint?: string; scopes: string[] }) {
            requests.push(request);
            return Promise.resolve({ accessToken: "interactive-token" });
        }

        public acquireTokenSilent() {
            return Promise.reject(new Error("No cached account."));
        }

        public getAllAccounts() {
            return [];
        }

        public handleRedirectPromise() {
            return Promise.resolve(undefined);
        }

        public ssoSilent() {
            return Promise.reject(new InteractionRequiredError());
        }
    }

    const globalWithMsal = globalThis as typeof globalThis & {
        msal?: {
            PublicClientApplication: typeof FakePublicClientApplication;
        };
    };
    globalWithMsal.msal = {
        PublicClientApplication: FakePublicClientApplication
    };

    try {
        const provider = new SsoTokenProvider({
            clientId: "f104fe0a-6b8a-446b-a623-cfbd7c7e2b11",
            tenantId: "8221c52a-2c7f-4da0-8b1f-34c6f692d915",
            redirectUri: "https://runtime-app.powerplatform.com/",
            loginHint: "owner@example.com"
        });

        const token = await provider.acquireTokenInteractive(
            "api://5ed8c4be-0464-434a-b2b6-55bc6953ce3b/access_as_user"
        );

        assert.equal(token, "interactive-token");
        assert.deepEqual(requests, [{
            loginHint: "owner@example.com",
            scopes: ["api://5ed8c4be-0464-434a-b2b6-55bc6953ce3b/access_as_user"]
        }]);
    } finally {
        delete globalWithMsal.msal;
    }
});

void test("silent iframe timeout falls back to the interactive login card", async () => {
    class MonitorWindowTimeoutError extends Error {
        public readonly errorCode = "monitor_window_timeout";
    }

    class FakePublicClientApplication {
        public acquireTokenPopup() {
            return Promise.resolve({ accessToken: "interactive-token" });
        }

        public acquireTokenSilent() {
            return Promise.reject(new Error("No cached account."));
        }

        public getAllAccounts() {
            return [];
        }

        public handleRedirectPromise() {
            return Promise.resolve(undefined);
        }

        public ssoSilent() {
            return Promise.reject(new MonitorWindowTimeoutError());
        }
    }

    const globalWithMsal = globalThis as typeof globalThis & {
        msal?: {
            PublicClientApplication: typeof FakePublicClientApplication;
        };
    };
    globalWithMsal.msal = {
        PublicClientApplication: FakePublicClientApplication
    };

    try {
        const provider = new SsoTokenProvider({
            clientId: "f104fe0a-6b8a-446b-a623-cfbd7c7e2b11",
            tenantId: "8221c52a-2c7f-4da0-8b1f-34c6f692d915",
            redirectUri: "https://runtime-app.powerplatform.com/",
            loginHint: "owner@example.com"
        });

        assert.equal(
            await provider.acquireToken(
                "api://5ed8c4be-0464-434a-b2b6-55bc6953ce3b/access_as_user"
            ),
            undefined
        );
    } finally {
        delete globalWithMsal.msal;
    }
});
