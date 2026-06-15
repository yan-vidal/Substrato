---
name: repo-reviver
description: Resurrects dormant, stale, or abandoned projects by safely bringing their dependencies and toolchain back to life — inventories installed packages, researches online what changed (changelogs, breaking changes, migration guides, CVEs), builds an automated test fence around affected code before touching anything, then works package-cluster by package-cluster with the user in an interactive terminal session to decide update/skip/pin/replace, with one reversible commit per cluster. Use this skill whenever the user wants to revive, resurrect, modernize, un-rot, or "make run again" an old/dead/paused project, update outdated or vulnerable dependencies without breaking things, deal with deprecated/abandoned packages, or fix a repo that no longer installs or builds. Integrates with .distill/ (repo-distiller), .backlog/ (backlog-builder), and the spec pipeline — usable before or after them.
---

# Repo Reviver

Bring a dormant project back to a state where it installs, builds, runs, and its dependencies are current enough to develop on — **without changing observable behavior**. Resurrection is not modernization: the contract is "same project, alive again". Anything bigger than that gets escalated, not smuggled in.

The session is interactive by design: you research and recommend; **the user decides every cluster's fate, with the why recorded**. Same consensus contract as the rest of this stack — your judgment proposes, the user disposes, and every decision is persisted the moment it's made.

## Operating principles

1. **Baseline before anything.** You cannot prove "the update didn't break it" without a green "before". No dependency moves until the project installs, builds, and shows a heartbeat at current versions — and if it can't, *achieving baseline is the first phase of revival*, not a blocker to skip past.
2. **Characterization over correctness.** Dormant projects rarely have meaningful tests. Before touching a cluster, write *characterization tests* (Feathers): capture what the code **does today** — current behavior, bugs included — on the surfaces that cluster touches. The fence protects observed behavior, not ideal behavior; fixing bugs mid-upgrade conflates two changes and makes regressions undiagnosable.
3. **The cluster, not the package, is the unit of work.** Coupled packages move together or break (`react`+`react-dom`+`@types/react`; `eslint`+its plugins; `jest`+`ts-jest`). One cluster = one research dossier = one decision = **one commit** = one atomic rollback unit.
4. **Risk-ordered, never alphabetical.** Security fixes → toolchain/test infra (so the fence itself runs) → low-risk patch/minor batch → majors one at a time → replacements of dead packages.
5. **Resurrect, don't rewrite.** When an "update" reveals itself as an architecture migration (Vue 2→3, webpack→Vite, Python 2→3), stop digging: escalate it as a backlog card and move on. The skill's job ends where redesign begins.
6. **Write as you go.** Upgrade sessions are long and terminals die. The ledger on disk is the source of truth; killing the session at any moment must lose at most the cluster in progress.

## Inputs & stack integration

**Ecosystem detection.** Identify every manifest present (polyglot repos have several) and use each ecosystem's *real* commands — discovered from the repo (scripts, Makefile, CI), never invented:

| manifest | outdated | audit |
|---|---|---|
| package.json (npm/pnpm/yarn/bun) | `<pm> outdated` | `<pm> audit` |
| pyproject/requirements (pip/poetry/uv) | `pip list --outdated` / `poetry show --outdated` | `pip-audit` |
| Cargo.toml | `cargo outdated` | `cargo audit` |
| go.mod | `go list -u -m all` | `govulncheck ./...` |

(Table is illustrative — extend per ecosystem found. `osv-scanner` covers most as a fallback audit.)

**`.distill/` present:** use it as the usage index — `modules/*.md` tell you *where* each package's territory is; `INSIGHTS.md` invariants/scars/danger-zones tell you what an upgrade must not disturb. Check the fingerprint: if stale, trust source. **After the session, recommend a distill refresh** — you just invalidated parts of it.

**`.backlog/` present:** escalations become cards via the backlog-builder conventions (next `BL-NNN`, `origin: revival`, one-line acceptance, link back to the dossier). No backlog → write escalations to `.revive/ESCALATIONS.md` instead.

**Neither present:** lightweight survey (README, manifests, entry points) — enough to know what the project is and what its heartbeat should be.

## Output layout

```
.revive/
├── LEDGER.md       # the board: baseline, fence, cluster table with status + commits
├── dossiers/       # one research file per cluster (kept after decisions — it's the why)
│   └── react.md
└── DECISIONS.md    # append-only: every decision, one line, with reason  [same format as the stack]
```

**Cluster states:** `pending → researched → fenced → updated → verified` (happy path), or terminal `skipped | pinned | replaced | escalated | blocked`. Persist every transition immediately.

### LEDGER.md skeleton

```markdown
# Revival Ledger — <project>
Baseline: commit abc1234 · branch revive/2026-06 · install ✅ build ✅ heartbeat ✅ · tests: 12 pass (vitest, existing)
Heartbeat: `npm run dev` → GET /health 200 within 10s
Toolchain: node 14.17 → target 20 LTS (cluster 0)
| # | Cluster | Packages | Current → Target | Risk | Status | Commit |
|---|---------|----------|------------------|------|--------|--------|
| 0 | toolchain | node | 14.17 → 20.11 | high | verified | def5678 |
| 1 | security | lodash, minimist | CVE batch | P0 | verified | 9ab0123 |
```

Commit message convention — greppable, one per cluster: `revive(<cluster>): <pkgs> <old>→<new>`.

## Workflow

### 0 · Preflight & baseline

- Require a clean working tree (uncommitted changes → ask: commit or stash before anything).
- Detect ecosystems; locate real install/build/test/run commands.
- **Baseline attempt:** install → build → run existing tests → heartbeat. If any step fails, enter *fix-to-baseline* mode: this usually means runtime version (install the old one via `mise`/`nvm`/`asdf`/`pyenv` — pin it in the repo), dead registries/mirrors, or lockfile drift. Fixing-to-baseline changes **nothing** about dependency versions — never delete a lockfile as a "fix"; that destroys the only record of a known-working state.
- Safety anchor: create branch `revive/<yyyy-mm>` and tag the baseline commit. All work happens on the branch.

### 1 · Inventory & triage (silent)

Run outdated + audit across ecosystems. For each dependency also check **deadness**: archived repo, deprecation notice, years since last release. Then form clusters by coupling (peer deps, plugin families, shared majors) and tier them:

- **T0 security** — known CVEs. Jumps every queue.
- **T1 toolchain & test infra** — runtime version, test runner, build tool. Updated early so the fence itself is trustworthy.
- **T2 patch/minor, no documented breaking** — candidates for one batched commit.
- **T3 majors** — one cluster at a time, full cycle each.
- **T4 dead/deprecated** — not updates: *replacement decisions* (or a conscious pin).

### 2 · Kickoff — one turn, like a flight briefing

Present in a single compact message: baseline status, the numbers (N deps · X majors behind · Y CVEs · Z dead), the proposed **test approach** — use the existing framework if there is one; otherwise propose the ecosystem's idiomatic choice with 1–2 alternatives and a one-line tradeoff each (this is decided **once**, here, not per package) — the proposed **heartbeat** definition (the minimal "it's alive" check: server boots and `/health` returns 200, CLI `--help` exits 0, main script processes a fixture), the branch name, and the attack order. Ask for corrections or a go.

### 3 · Fence (before the first risky cluster)

Build the safety net the upgrades will be judged against:

- **Heartbeat test** — always, automated, fast. The universal minimum.
- **Characterization tests per cluster** — find the cluster's blast radius (distill modules → anchors, or grep imports), then pin down current observable behavior at those surfaces: real outputs for real inputs, snapshot/golden-master style where output is complex. Test what **is**, not what should be; if you find a bug, note it in the dossier — don't fix it now.
- Run the full fence on baseline. It must be green *before* any bump — a fence that never passed proves nothing. Record fence scope in LEDGER.

T2 patch batches may proceed under heartbeat + existing tests alone; T3/T4 clusters get characterization on their surfaces first. Scale fence effort to risk, and state in the dossier what the fence does *not* cover (`?` where coverage is thin).

### 4 · Cluster loop — the heart of the session

For each cluster in tier order:

**Research online** (per-cluster timebox: 3–6 focused searches; stop early when sources repeat): official changelog/release notes between current and target, the migration guide if any, **official codemods** (they exist more often than people check), and GitHub issues matching "upgrade to vX" for landmines the changelog omits. Discipline: paraphrase only; cite exact versions; every breaking-change claim carries its source — or `?` if inferred.

**Write the dossier** (`dossiers/<cluster>.md`), then present its compact form and ask for the decision:

```
── cluster 4: react ── react, react-dom, @types/react · 16.8 → 18.3 · risk HIGH
Breaking: ReactDOM.render→createRoot [v18 notes] · auto-batching alters effect timing [v18 notes]
          · ? StrictMode double-render may surface in src/polling.ts
Usage here: 14 files · entry src/main.tsx#render · no legacy class lifecycles found
Codemod: official react-codemod available for root API
Fence: heartbeat + char tests on render pipeline (tests/char/react-render.spec) — green at baseline
Recommend: update now via codemod; review effect timing in polling.ts after bump
[update / skip / pin / replace / split / later]
```

Questions only when they change the decision, **max 2–3** (the backlog-builder rule). Echo the resolved choice in one line before executing.

**Execute & verify.** Bump the cluster (lockfile updated, never bypassed) → run the **verify ladder**: install → build → typecheck → full test suite + fence → heartbeat. On failure: diagnose against the researched breaking changes; fix forward if the fix is mechanical and within scope, otherwise `git revert` the cluster commit, mark `blocked` with the reason, and move on — a blocked cluster is information, not defeat. On green: commit (`revive(react): react* 16.8→18.3`), update LEDGER row, append the DECISIONS line.

**Special flows:**
- *T2 batch:* present the whole batch as one-liners, single confirmation, one commit — the batch-confirm pattern; any package the user names gets pulled out for individual treatment.
- *T4 replacement:* dossier compares 1–3 alternatives (API distance, maintenance health, migration effort) vs. a **conscious pin** (accepted risk, recorded). Replacement chosen → it becomes its own cluster with its own fence.
- *Escalation:* effort clearly beyond a session, or behavior change unavoidable → create the backlog card (or ESCALATIONS entry), link the dossier, mark `escalated`. Say what makes it big; don't attempt it.
- *Add-anytime:* the user can redirect at any point (`skip`, `later`, `+ also look at <pkg>`, `status`, `done`) — same session grammar contract as backlog-builder: save a resume pointer, handle it, return explicitly.

### 5 · Close-out

Summary: clusters by outcome, CVEs resolved vs. explicitly accepted, escalations created, fence inventory (tests now exist — that's a permanent asset of the revival), remaining `pending`/`blocked`. Recommend: merge strategy for `revive/<date>`, a distill refresh if `.distill/` exists, and note the session is resumable. If the repo has `CLAUDE.md`/`AGENTS.md`, add one line pointing to `.revive/LEDGER.md` while work remains.

## Resuming

`.revive/LEDGER.md` exists at start → resume mode: read LEDGER + DECISIONS, verify the recorded baseline/fence still hold (run the ladder once — the repo may have moved), summarize state in ≤5 lines, continue from the first non-terminal cluster. Honor past decisions: never re-propose a `skipped`/`pinned` cluster unless the user raises it or something changed (new CVE, new major) — and say what changed.

## Quality bar

Reject in self-review:
- Any bump before a green baseline; lockfile deleted or bypassed; cluster updated without a dossier.
- Breaking-change claims with neither source nor `?`; mixed clusters in one commit; behavior "improvements" smuggled into an upgrade.
- Proceeding past a red fence without an explicit, recorded user decision; rewriting where escalation was due.

Require:
- One reversible commit per cluster, conventional message; every decision in DECISIONS.md with a why.
- Ledger transition persisted before the next cluster starts; CVEs either resolved or explicitly accepted by the user.
- Fence green at baseline before first risky bump; heartbeat green at every verify.

Final check before close-out: **does `git log` on the revive branch read as a sequence of independently revertible clusters? could a fresh session resume from the ledger without re-asking anything already decided? and does the project actually run?** If any answer is no, the revival isn't done — it's just stopped.
