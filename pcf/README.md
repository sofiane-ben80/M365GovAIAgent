# Governor365 Agent Chat PCF

This folder contains the custom Power Apps component framework control used to
host the Copilot Studio orchestrator beside the Governor365 canvas dashboard.

## Projects

- `Governor365AgentChat` - React PCF control using Bot Framework Web Chat and
  short-lived Direct Line tokens.
- `M365GovernanceSolution` - canonical solution build project. It combines the
  unpacked `M365Governance_2_0_0_0` source with the PCF project so the control,
  Canvas app, agents, flows, Dataverse components, and environment variables
  are packaged together.
- `Governor365AgentChatSolution` - isolated control-only package retained for
  component development diagnostics. Do not use it for a Governor365 release.

## Build and test

```powershell
Set-Location .\pcf\Governor365AgentChat
npm install
npm test
npm run lint
npm run build -- --buildMode production

Set-Location ..\..
dotnet build .\pcf\M365GovernanceSolution\M365GovernanceSolution.cdsproj --configuration Release
```

The canonical solution build replaces `M365Governance_2_0_0_0.zip` with an
unmanaged package generated from `M365Governance_2_0_0_0/` and injects
`Governor365.AgentChat` as a type-66 root component. This is the development
import package. Export the complete solution as managed from the validated
source environment for test and production.

Do not commit or place a Direct Line secret in the control. Configure the
control with the token endpoint copied from the Copilot Studio **Mobile app**
channel. That endpoint issues a short-lived token and is validated by the
control before use.

See [PCF Agent Chat Integration](../docs/28-PCF-Agent-Chat-Integration.md) for
the protocol, deployment, Canvas formulas, Copilot Studio wiring, and security
requirements.
