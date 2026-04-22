# AGENTS.md — AI Agent Instructions for omg-dmn-spec

> **Read this file first.** Treat it as higher priority than README.md or
> other repository documentation. Only a direct user prompt overrides it.

## Purpose

This repository contains the **machine-readable artifacts** (XML Schemas and
examples) of the OMG Decision Model and Notation (DMN) specification.
Changes here can be **normative** — they affect a published standard.
Proceed carefully.

## Instruction Priority

1. Direct user task / prompt
2. **This file (AGENTS.md)**
3. README.md, commit-message-template.txt, repository docs
4. Inline comments and local conventions in source files

## Repository Map

| Path | Content | Notes |
|------|---------|-------|
| `xsd/DMN.xsd` | Main DMN model schema | **Normative** |
| `xsd/DMNDI.xsd` | DMN Diagram Interchange schema | **Normative** |
| `SCE/DI.xsd` | Base Diagram Interchange schema (adopted from SCE) | **Normative** |
| `SCE/DC.xsd` | Diagram Common schema (adopted from SCE) | **Normative** |
| `catalog.xml` | XML catalog mapping namespace and schemaLocation URIs → local XSDs | |
| `xsd/dmn-namespace-utils.sh` | Bash variables for all versioned namespace URIs | |
| `xsd/migrate-to-new-namespaces.sh` | sed-based namespace migration tool | |
| `xsd/test-xsd.sh` | Cross-version XSD validation (xmllint) | |
| `examples/` | Non-normative DMN XML examples | Must validate against `xsd/DMN.xsd` |
| `xmi/` | MagicDraw XMI exports of meta-model | Rarely edited |
| `Makefile` | Local xmllint validation targets (mirrors CI, uses `catalog.xml`) | |
| `.github/workflows/main.yml` | CI: validates every example against `xsd/DMN.xsd` via xmllint | |

## Setup & Validation Commands

```bash
# Preferred: run the Makefile targets (mirrors CI). XSD imports are all
# relative paths, so CLI validation works without the catalog; the catalog
# is primarily used by IDE validation to resolve the https://www.omg.org/...
# xsi:schemaLocation URIs in example .dmn files.
make              # lint-xsd + lint-examples + validate
make lint-xsd     # XSD well-formedness (xsd/DMN.xsd, xsd/DMNDI.xsd, SCE/DI.xsd, SCE/DC.xsd)
make lint-examples # .dmn well-formedness
make validate     # .dmn schema validation against xsd/DMN.xsd
make ci-local     # run the GitHub Actions workflow locally via `act` (Docker required)
make -k           # keep going on errors — see every failure in one run

# Direct xmllint (what the Makefile invokes under the hood)
xmllint --schema xsd/DMN.xsd --noout "examples/path/to/file.dmn"
xmllint --noout xsd/DMN.xsd xsd/DMNDI.xsd SCE/DI.xsd SCE/DC.xsd

# Migrate examples from DMN 1.6 to 1.7 namespaces (requires `sponge` from moreutils)
xsd/migrate-to-new-namespaces.sh

# Cross-version backward-compatibility check (run from a directory with .dmn files)
xsd/test-xsd.sh
```

> **Do not invent commands.** Use the `make` targets, `xmllint` invocations
> shown above, or scripts found in the repository. No `npm` or `mvn` build
> system exists here.

## Coding & Documentation Standards

- **Namespace URIs are version-free** for the current revision (DMN 1.7):
  `https://www.omg.org/spec/DMN/` (model),
  `https://www.omg.org/spec/DMN/DMNDI/` (diagram interchange),
  `https://www.omg.org/spec/DMN/FEEL/` (FEEL).
  DI and DC schemas are adopted from SCE:
  `https://www.omg.org/spec/SCE/DI/` (diagram interchange base),
  `https://www.omg.org/spec/SCE/DC/` (diagram common).
  Older versioned URIs (with timestamps like `20240513`) are only in
  `dmn-namespace-utils.sh` for migration purposes.
- **Preserve XML formatting** — indentation style, attribute ordering,
  and namespace declaration order as found in the file being edited.
  Trailing-newline-on-save is enforced via `.vscode/settings.json`
  (`files.insertFinalNewline`) — keep it.
- **Element ordering in XSD matters** — `xsd:sequence` constrains child
  element order; do not reorder elements.
- **Folder layout mirrors the canonical URL structure**: `xsd/` holds the
  DMN-namespace schemas (published under `https://www.omg.org/spec/DMN/`),
  `SCE/` (peer folder at repo root) holds SCE-namespace schemas (published
  under `https://www.omg.org/spec/SCE/`). This lets relative
  `schemaLocation` values work identically offline and online — e.g.
  `../SCE/DC.xsd` in `xsd/DMNDI.xsd` resolves to `SCE/DC.xsd` locally and
  to `https://www.omg.org/spec/SCE/DC.xsd` online.
- **`schemaLocation` convention** inside XSDs: use relative paths that
  follow the mirrored layout (`../SCE/DC.xsd`, `DMNDI.xsd`, etc.). Do NOT
  use absolute `https://www.omg.org/...` URLs — mixing URL and relative
  forms for the same namespace across different files makes libxml2 emit
  a "schema already imported" warning because it compares the raw
  `schemaLocation` strings. Preserve the canonical OMG URL as
  documentation via `<xsd:annotation><xsd:documentation>` inside the
  `<xsd:import>` (see `xsd/DMNDI.xsd` for the pattern).
- **Example namespace prefixes**: hand-maintained examples under
  `examples/Diagram Interchange/` declare the DMN namespace with the
  `dmn:` prefix (`xmlns:dmn="https://www.omg.org/spec/DMN/"`) and write
  elements as `<dmn:definitions>`, `<dmn:decision>`, etc. Vendor-exported
  examples (e.g. `examples/Chapter 12 …/` from Trisotech) use their own
  prefix like `semantic:` — do NOT normalize those to `dmn:`, they're
  intentionally verbatim.
- **Commit messages** follow the template in `commit-message-template.txt`:
  `DMN16-<ISSUE>/DMN16-<PROPOSAL> <SUMMARY>`.
- **One commit per JIRA issue**, squash if needed.

## Allowed Changes

- Editing XSD types, elements, attributes when requested by a user task.
- Adding, modifying, or removing example `.dmn` files in `examples/`.
- Updating namespace URIs consistently across all files (use
  `dmn-namespace-utils.sh` variables and `migrate-to-new-namespaces.sh`).
- Updating `catalog.xml` when namespace URIs change.
- Updating CI workflow when examples are added or removed.

## Prohibited Changes

- **Never silently relax XSD constraints** (types, cardinalities,
  minOccurs/maxOccurs, restrictions, keys/keyrefs) — if a relaxation seems
  needed, ask the user to confirm.
- Do not change namespace URIs without explicit instruction.
- Do not delete or rename XSD files without explicit instruction.
- Do not modify `xmi/` files unless specifically asked.
- Do not add new tooling, build systems, or dependencies.
- Do not add generated documentation or markdown files unless requested.

## PR Expectations

- Keep diffs **minimal and tightly scoped** to the requested change.
- Reference the JIRA issue number in commit messages.
- All examples must pass CI (`xmllint --schema xsd/DMN.xsd`).
- If a schema change would break existing examples, fix the examples in
  the same commit.

## Safety Checks Before Finishing

Before marking work as complete, verify:

- [ ] **Full local validation**: `make` (or `make -k` to see all failures) passes —
      covers XSD well-formedness, `.dmn` well-formedness, and schema validation
      of every example against `xsd/DMN.xsd`.
- [ ] **No namespace/version drift**: no stale versioned URIs were
      introduced or left behind (grep for old timestamps if namespaces
      were touched).
- [ ] **Diff review**: no accidental normative changes (unexpected type
      changes, removed attributes, relaxed cardinalities).

## When to Ask Humans

- Any change that could be **normative** (XSD constraints, new elements/types,
  removed attributes) and was not explicitly requested.
- Ambiguity about which DMN version a change targets.
- Namespace URI decisions — these affect every vendor implementation.
- Anything that would break backward compatibility.

---

### Claude Code compatibility

This same `AGENTS.md` applies in Claude Code sessions. Claude Code should
read and follow these instructions with the same priority ordering.
