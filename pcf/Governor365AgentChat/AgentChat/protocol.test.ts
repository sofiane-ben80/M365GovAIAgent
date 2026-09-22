import { strict as assert } from "node:assert";
import { test } from "node:test";
import {
    MAX_CONTEXT_LENGTH,
    MAX_PROMPT_LENGTH,
    createContextEnvelope,
    getDirectLineUserId,
    getTokenEndpointDetails,
    parseCanvasAction,
    parseContext,
    parseContextPrompt,
    parseOAuthCardTokenExchange,
    parsePrompt
} from "./protocol";

void test("derives the regional settings endpoint from a commercial token endpoint", () => {
    const details = getTokenEndpointDetails(
        "https://abc.environment.api.powerplatform.com/powervirtualagents/botsbyschema/test/directline/token?api-version=2022-03-01-preview"
    );

    assert.equal(
        details.regionalSettingsEndpoint,
        "https://abc.environment.api.powerplatform.com/powervirtualagents/regionalchannelsettings?api-version=2022-03-01-preview"
    );
});

void test("accepts a US government Power Platform endpoint", () => {
    const details = getTokenEndpointDetails(
        "https://abc.environment.api.powerplatform.us/powervirtualagents/botsbyschema/test/directline/token?api-version=2022-03-01-preview"
    );

    assert.match(details.tokenEndpoint, /^https:\/\/abc\.environment\.api\.powerplatform\.us\//);
});

void test("rejects insecure and untrusted token endpoints", () => {
    assert.throws(
        () => getTokenEndpointDetails(
            "http://abc.environment.api.powerplatform.com/powervirtualagents/test?api-version=1"
        ),
        /HTTPS/
    );
    assert.throws(
        () => getTokenEndpointDetails(
            "https://powerplatform.com.example.org/powervirtualagents/test?api-version=1"
        ),
        /hosted by Power Platform/
    );
});

void test("parses only bounded JSON objects as canvas context", () => {
    assert.deepEqual(parseContext('{"recordId":"123","persona":"owner"}'), {
        recordId: "123",
        persona: "owner"
    });
    assert.throws(() => parseContext("[1,2,3]"), /JSON object/);
    assert.throws(() => parseContext(`{"value":"${"x".repeat(MAX_CONTEXT_LENGTH)}"}`), /exceeds/);
});

void test("creates a versioned context envelope", () => {
    const envelope = createContextEnvelope({ recordId: "123" }, 7);

    assert.equal(envelope.schemaVersion, "1.0");
    assert.equal(envelope.source, "Governor365.Canvas");
    assert.equal(envelope.sequence, 7);
    assert.deepEqual(envelope.context, { recordId: "123" });
    assert.doesNotThrow(() => new Date(envelope.sentAt));
});

void test("normalizes and bounds canvas-initiated prompts", () => {
    assert.equal(parsePrompt("  Assess the selected site.  "), "Assess the selected site.");
    assert.equal(parsePrompt("   "), "");
    assert.throws(() => parsePrompt("x".repeat(MAX_PROMPT_LENGTH + 1)), /exceeds/);
});

void test("reads a versioned prompt from canvas context", () => {
    assert.deepEqual(
        parseContextPrompt({
            canvasPromptText: "  Review the selected site. ",
            canvasPromptVersion: 3
        }),
        {
            text: "Review the selected site.",
            version: 3
        }
    );
    assert.equal(parseContextPrompt({ canvasPromptText: "Review", canvasPromptVersion: 0 }), undefined);
    assert.equal(parseContextPrompt({ canvasPromptText: "", canvasPromptVersion: 1 }), undefined);
    assert.throws(
        () => parseContextPrompt({
            canvasPromptText: "x".repeat(MAX_PROMPT_LENGTH + 1),
            canvasPromptVersion: 1
        }),
        /exceeds/
    );
});

void test("reads and validates the Direct Line token user identity", () => {
    const payload = Buffer.from(JSON.stringify({ user: "direct-line-user" })).toString("base64url");

    assert.equal(getDirectLineUserId(`header.${payload}.signature`), "direct-line-user");
    assert.throws(() => getDirectLineUserId("not-a-token"), /malformed/);

    const missingUserPayload = Buffer.from(JSON.stringify({ bot: "test" })).toString("base64url");
    assert.throws(
        () => getDirectLineUserId(`header.${missingUserPayload}.signature`),
        /does not contain a user identity/
    );
});

void test("accepts only versioned named canvas actions", () => {
    assert.deepEqual(
        parseCanvasAction({
            schemaVersion: "1.0",
            name: "openSite",
            correlationId: "abc",
            payload: { siteId: "123" }
        }),
        {
            schemaVersion: "1.0",
            name: "openSite",
            correlationId: "abc",
            payload: { siteId: "123" }
        }
    );
    assert.equal(parseCanvasAction({ schemaVersion: "2.0", name: "openSite" }), undefined);
    assert.equal(parseCanvasAction({ schemaVersion: "1.0", name: "" }), undefined);
});

void test("extracts token exchange details only from OAuth cards", () => {
    assert.deepEqual(
        parseOAuthCardTokenExchange({
            attachments: [{
                contentType: "application/vnd.microsoft.card.oauth",
                content: {
                    connectionName: "Governor365 auth",
                    tokenExchangeResource: {
                        id: "exchange-id",
                        uri: "api://00000000-0000-0000-0000-000000000000/access_as_user"
                    }
                }
            }]
        }),
        {
            connectionName: "Governor365 auth",
            id: "exchange-id",
            uri: "api://00000000-0000-0000-0000-000000000000/access_as_user"
        }
    );
    assert.equal(parseOAuthCardTokenExchange({ attachments: [] }), undefined);
    assert.equal(
        parseOAuthCardTokenExchange({
            attachments: [{
                contentType: "application/vnd.microsoft.card.oauth",
                content: { connectionName: "Governor365 auth" }
            }]
        }),
        undefined
    );
});
