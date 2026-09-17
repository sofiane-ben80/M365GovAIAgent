# Governor Connector Contracts

Connector contracts expose stable Governor operations to Copilot Studio. They
do not contain credentials and are not the authorization boundary by
themselves.

## Initial connector

`governor-advisor-broker/apiDefinition.swagger.json` defines the first ten
Policy and Readiness operations:

- `SearchApprovedPolicy`
- `GetPolicyLifecycleStatus`
- `GetAggregateGovernanceFindings`
- `RunMaturityAssessment`
- `DraftPolicyArtifact`
- `GetReadinessBaseline`
- `CheckPrerequisite`
- `GetCapabilityClaim`
- `ListRelevantServiceChanges`
- `RunReadinessAssessment`

The contract deliberately has no caller identity parameter. The broker must
derive the caller and tenant from the validated access token, enforce the
operation's audience and scope, and fail closed.

Before importing the Swagger file as a Power Platform custom connector:

1. replace the `.invalid` host with the deployed broker hostname;
2. replace the placeholder API scope with the Entra app registration scope;
3. configure the connector OAuth client through deployment settings or the
   target environment, never in source;
4. verify every operation returns correlation, freshness, source, partial
   result, and error metadata;
5. run unauthorized, stale, partial, timeout, and malformed-input tests.

The connector is a contract scaffold. No live endpoint is deployed yet.
