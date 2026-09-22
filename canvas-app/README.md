# Governor365 Canvas app

The Governor365 Canvas app is the solution's primary user experience. It
combines role-specific visual governance workflows with an integrated Copilot
Studio custom agent:

- owner and administrator dashboards provide search, risk filters, summary
  cards, site details, and governed actions;
- the embedded agent gives a proactive briefing when each role opens its
  workspace;
- selecting a site refreshes the agent's approved Canvas context;
- Canvas buttons can initiate visible, grounded conversational reviews; and
- agent-to-Canvas events use a versioned, allowlisted action contract.

Canvas context is a usability signal only. The agent's Power Automate tools
independently derive caller identity and authorize every operation.

The current Canvas app is solution-owned and stored in the canonical
Governor365 2.0 solution:

- Source: `../M365Governance_2_0_0_0/CanvasApps/`
- Editable unpacked source: `./src/`
- Import package: `../M365Governance_2_0_0_0.zip`
- Deployment status: `../docs/25-Deployment-Status-and-Runbook.md`
- Implementation handoff: `../docs/27-Implementation-Handoff.md`
- PCF integration: `../docs/28-PCF-Agent-Chat-Integration.md`

The former SQL-bound Canvas proof of concept is retained at
`../archive/legacy-2026-09-19/canvas-app/` for migration history only.

## Source and packaging workflow

The published `.msapp` in the canonical solution is the deployment artifact.
The `src` directory is its editable source representation and includes the
generated PCF control template. After a Studio change is saved and published,
sync both representations:

```powershell
pac canvas download `
  --environment 9417045e-87bb-eac8-bda1-850674b11405 `
  --name 86045adc-9862-4d7e-b14e-25831abf4fc0 `
  --file-name ..\M365Governance_2_0_0_0\CanvasApps\sb_governor365dashboard_b39d0_DocumentUri.msapp `
  --overwrite

pac canvas unpack `
  --msapp ..\M365Governance_2_0_0_0\CanvasApps\sb_governor365dashboard_b39d0_DocumentUri.msapp `
  --sources .\src

dotnet build ..\pcf\M365GovernanceSolution\M365GovernanceSolution.cdsproj `
  --configuration Release
```

`pac canvas pack` and `pac canvas unpack` are deprecated but remain the
repository's current source-synchronization mechanism. Expect `PA2001`
checksum warnings when intentionally packing edited source. Validate formulas
in Power Apps Studio; the current `pac canvas validate` command applies an
incompatible schema to generated `Other\Src\*.pa.yaml` files.

The owner screen contains `AgentChatOwner`, and the administrator screen
contains `AgentChatAdmin`. Both use the same PCF and bounded context/action
contract documented in
`../docs/28-PCF-Agent-Chat-Integration.md`.

## Visual design

The owner and administrator screens use the same dark, Teams-oriented visual
system:

- a slate application background and elevated content panels;
- compact 56-pixel site-list rows that show tenant-relative paths in a
  320-pixel results column;
- a wider, scrollbar-free three-column site-detail grid with 15 governance
  fields, prominent action and compliance indicators, and a 422-pixel
  assistant panel;
- compact summary cards with semantic colors for urgent conditions;
- high-contrast text, links, selection indicators, and keyboard focus.

Canvas galleries do not expose scrollbar width or color properties. The site
details therefore fit in a fixed five-row grid with its scrollbar disabled.
Its first row prioritizes the recommended action and compliance status, while
the underlined `View` link opens the selected SharePoint site.
The results gallery retains its native scrollbar for keyboard and pointer
accessibility, while the shorter templates reduce how often it is needed.

The main screen remains an operational triage workspace. Analytics should be
added as a separate screen or Teams tab so charts do not compete with search,
site details, and the assistant. Prefer native Canvas charts for a small number
of live operational metrics. Use an embedded Power BI report only when the
reporting requirement needs historical trends, richer drill-through, or a
governed semantic model.
