---
name: spec-compiler
description: Compiles a confirmed backlog card into executable technical implementation specs at two capability targets — a compact spec (low-token, high-freedom) for frontier models and a full spec (step-by-step playbook with embedded knowledge) for smaller/cheaper models — so an implementing agent can complete the task by reading one file, knowing exactly what to change, how, where, and with what. Use this skill whenever the user asks to technically specify a card or task, write a tech spec / implementation spec / design doc for a backlog item, "prepare BL-NNN for implementation", detail what/how/where for a change, or generate agent-ready instructions from a .backlog card — even if they don't say "spec". Integrates with the .distill/ corpus (repo-distiller) and .backlog/ board (backlog-builder).
---

# Spec Compiler

Compile a `confirmed` backlog card (the *source*) into implementation specs (the *binaries*) for two capability targets. The implementing agent reads exactly one file and starts working — no archaeology, no guessing, no questions the spec should have answered.

```
card (what/why)  ──compile──►  compact.md   (contract only — frontier models)
                          └──►  full.md      (contract + playbook — smaller models)
```

## Theory — the axis is what remains open, not token count

Each artifact in the pipeline closes a class of decisions and leaves the rest open:

| artifact | closed | left open |
|---|---|---|
| card (backlog-builder) | product: what & why, acceptance | design + implementation |
| **compact spec** | product + **observable design**: interfaces, schemas, behavior, constraints | internal tactics: structure, order, helpers |
| **full spec** | everything except mechanical execution | nothing that requires judgment |

Token count is a *consequence* of this axis, not the goal. The reasoning:

- **Strong models are hurt by over-specification.** Give a frontier model a step-by-step plan and it will obediently follow it — including its suboptimal parts — instead of finding a better path. Burying three critical constraints inside forty instructions also dilutes attention on the three that matter. The compact tier therefore states the destination and the guardrails, and deliberately *withholds* the route.
- **Weak models are killed by under-specification.** Every open design decision is an opportunity to go wrong. The full tier closes them all: ordered plan, signatures, edge cases enumerated, codebase traps pre-warned, verification after every step. What remains is typing.
- **Both tiers must produce the same observable result.** Anything visible from outside the change — public interfaces, schemas, wire formats, user-facing behavior, invariants — is **contract** and appears identically in both tiers. Anything internal to the change — file-local structure, step order, naming of helpers — is **playbook** and exists only in full. This is what prevents the two targets from drifting into two different features.

## Inputs

1. **The card** — `.backlog/cards/BL-NNN-*.md`, status `confirmed`. Refuse to spec `proposed` cards (consensus first — that's backlog-builder's job) and `deferred` ones (pointless spend).
2. **The `.distill/` corpus** when present — use it as the *index*, never the *truth*: INDEX → MAP (notation) → the modules covering affected areas → INSIGHTS, mining specifically **global invariants, hidden couplings, scars, danger zones, and lies** that touch this card's territory. Those five sections are where implementation traps live.
3. **The source code** — the truth. Without `.distill/`, investigate the code directly (more expensive, same obligations).

Inherit the stack's notation everywhere: `path#symbol` anchors, `!` critical, `?` unverified inference, `[gen]` generated. A spec consumer already fluent in the distill corpus must not need a second legend.

Greenfield cards (no code yet) are still speccable: touchpoints become files-to-create, and the contract carries proportionally more weight.

## Output layout

```
.backlog/specs/
├── BL-014-webhook-dlq.compact.md
└── BL-014-webhook-dlq.full.md
```

Flat, slug inherited from the card, tier as suffix — trivially greppable, and an orchestrator routes by appending `.compact.md` or `.full.md` to one prefix.

After writing both files: add `spec_compact:` and `spec_full:` paths to the card's frontmatter (additive — never touch its other fields), and append one line to `DECISIONS.md`: `2026-06-09 · BL-014 spec'd @ <commit> — <one-line approach> [spec-compiler]`.

### Spec frontmatter (both tiers)

```yaml
---
id: BL-014
card: ../cards/BL-014-webhook-dlq.md
tier: compact            # compact | full
commit: abc1234          # HEAD at investigation time
routing: compact-ok      # compact-ok | full-for-all (see Routing)
updated: 2026-06-09
---
```

**Routing:** default `compact-ok` (frontier reads compact, others read full). Set `full-for-all` when the blast radius justifies maximum guidance regardless of model: migrations or any irreversible data change, security/auth surfaces, payment paths, anything the distill marks `!`. The field is a recommendation to the orchestrator, not enforcement.

## The shared contract

The contract is the first section of **both** files and must be **byte-identical** between them — verify with a diff before delivering; a sync failure is a hard error. Updating one tier means updating both in the same operation.

```markdown
## Contract
Goal: <1–2 lines — the observable result, not the activity>
Touchpoints:
- src/payments/hooks.ts#stripeWebhook — route exhausted retries to DLQ instead of dropping
- db/migrations/ — new table `webhook_dlq` (schema below)
- src/admin/routes.ts — list + replay endpoints
Interfaces:
- table webhook_dlq(id, event_id uniq, payload jsonb, error text, failed_at, replayed_at?)
- POST /admin/dlq/:id/replay → 202 | 409 if already replayed
Constraints:
- ledger is append-only (!) — replay must be idempotent, never double-write [INSIGHTS#invariants]
- amounts stay integer cents end-to-end [core/money]
- do not touch retry/backoff logic itself — out of scope per card
Acceptance → verify:
- >5 failed retries lands in DLQ            → npm test -- dlq.spec
- admin list + replay works                  → npm test -- admin-dlq.spec
- replay is idempotent (409 on second call)  → covered by same suite
Anchors: .distill/modules/payments.md · src/payments/hooks.ts · src/db/ledger.ts#append
Staleness: if HEAD ≠ commit above, re-verify Touchpoints before starting.
```

Section semantics: **Goal** is outcome-shaped. **Touchpoints** answer *where* with one line of *what* each — every anchor verified to exist during investigation. **Interfaces** are exact (signatures, schemas, status codes): this is the largest share of the "observable design" the contract closes. **Constraints** carry their origin in brackets — an implementer who knows *why* a rule exists violates it less. **Acceptance → verify** maps every card acceptance item to a concrete command or check; acceptance without a verification path is not done being specified. The **Staleness** line is a standing instruction to the future implementer, not metadata.

## Compact tier — frontier target

`= frontmatter + Contract.` Nothing else. Budget: **≤500 tokens**.

Resist the urge to "help a little" with hints or a suggested order — every tactical hint added to compact is a freedom removed from a model that likely had a better idea, and a token spent twice. If during investigation you discover knowledge that feels unsafe to omit, it is by definition either a *constraint* (→ contract, both tiers) or a *trap* (→ full's Gotchas). There is no third bucket.

## Full tier — guided target

`= frontmatter + Contract (identical) + Playbook.` Budget: **≤2,500 tokens**. If a faithful playbook cannot fit, the card is too big — send it back to backlog-builder to split (the same instinct as "XL never enters confirmed").

Playbook sections, in order:

```markdown
## Plan
1. Migration: create webhook_dlq per Interfaces → verify: npm run migrate && psql \d webhook_dlq
2. hooks.ts#stripeWebhook: on retry-exhausted, insert DLQ row instead of drop → verify: npm test -- hooks
3. ...each step: action → files → verify command
## Sketches
<signatures + skeletons ≤15 lines each, marked `// sketch — adapt to local style`; never the full
 paste-ready implementation. Trivial exact snippets (imports, config keys) are fine.>
## Edge cases
- replay of already-replayed entry → 409, no ledger write
- malformed payload in DLQ row → replay returns 422, row kept
## Gotchas
- webhook events arrive out of order ~ existing version check at #applyEvent handles it — reuse, don't reinvent [INSIGHTS#scars]
- `getUser` also mutates last_seen — do not call it in the replay path [INSIGHTS#lies]
## Do not touch
- retry/backoff implementation · generated client in src/gen/ [gen] · ledger write path beyond calling #append
## If stuck
- migration fails on FK → check seed order in db/seeds (known trap)
- after 2 failed attempts at any step: stop, report step + error verbatim, do not improvise around a constraint
## Done means
- [ ] all Acceptance → verify commands green
- [ ] npm run lint && npm run typecheck clean
- [ ] no files outside Touchpoints + tests modified
```

Rules of the playbook: **Plan** steps are ordered so the system stays consistent if interrupted between any two (migrations before code that needs them, flags before behavior they gate); every step ends in a runnable verify using the repo's real commands (discovered in investigation — never invent `npm test` for a repo that uses `make check`). **Sketches** are scaffolding, not implementation — you wrote them without executing anything, so a weak model pasting them verbatim would ship your unreviewed guesses; the ≤15-line cap keeps them honest. **Gotchas** is mined from INSIGHTS (scars, lies, couplings) plus your own investigation — it is the section that most distinguishes a spec written by someone who *read the code* from one written by someone who imagined it. **If stuck** must end with a stop condition: weak models improvising around an obstacle is the primary failure mode this tier exists to prevent.

## Workflow

### 0 · Locate
Input is a card ID/path, or batch mode ("spec everything confirmed"): process in priority order respecting `deps:` (dependencies first), and report any blocked cards at the end. Skip cards that already have specs with `commit == HEAD` unless asked to redo.

### 1 · Ingest
Read the card fully. Read distill INDEX → MAP → relevant modules → INSIGHTS filtered to the affected territory. Note every invariant, scar, lie, and `!` mark that intersects the card.

### 2 · Investigate — mandatory, the spec's actual substance
Open the real files behind every prospective touchpoint (distill is the index; code is the truth). Read the symbols you'll cite, their call sites, neighboring tests, and the repo's actual build/test/lint commands. Rules: **every anchor you write must have been seen to exist** — a `path#symbol` you didn't open is a `?` or doesn't ship; estimate the blast radius (who calls this? what breaks?); a spec written without opening files is fiction with confident formatting.

### 3 · Decide
Technical decisions (approach, schema shape, where logic lives) are **yours** — make them, and record a one-line rationale in the contract or DECISIONS when non-obvious. Product decisions are **not yours**: if investigation reveals an ambiguity the card's acceptance doesn't resolve (e.g. "replay re-sends the webhook OR re-processes locally — observably different"), do not pick. If the user is present, ask (≤3 options, recommend one); otherwise mark the card blocked (below).

### 4 · Write
Contract first — it forces the observable/internal sort. Then compact (= contract). Then full (= contract verbatim + playbook). Apply notation consistently; mark every unverified claim `?` rather than deleting it silently.

### 5 · Verify before delivering
- Contract sync: diff of the Contract section between tiers is empty.
- Anchor audit: every `path#symbol` exists at `commit` (spot-check with grep).
- Budgets: compact ≤500, full ≤2,500 tokens.
- Two-reader self-test: *(compact)* could a strong model start immediately and pass acceptance without asking anything investigation already answered? *(full)* is zero judgment left — is every remaining decision mechanical?

### 6 · Persist & link
Write both files, update the card frontmatter, append the DECISIONS line. In batch mode, persist per card as you go — never hold finished specs in memory across cards.

## Blocked protocol

When a product ambiguity or a contradiction (card acceptance vs. a code invariant) blocks the spec: set `status: blocked-spec` on the card *(additive status, backlog-builder treats it as needing a consensus pass)*, append `DECISIONS.md`: `BL-014 spec blocked — <the precise question, ≤2 lines> [spec-compiler]`, and write nothing in `specs/`. A spec that papers over an open product question with a silent assumption is worse than no spec — it launders a guess into instructions.

## Quality bar

Reject in self-review:
- Contract drift between tiers; anchors never opened during investigation; constraints without origin.
- Tactical hints inside compact; paste-ready full implementations inside Sketches; invented verify commands.
- Acceptance items with no mapped verification; playbooks ending without a stop condition; silent product decisions.

Require:
- Both tiers same observable result by construction (shared contract, verified by diff).
- Every claim verified-or-`?`; every verify command real; budgets respected; staleness line present.

Final check: **hand the compact to a strong model and the full to a weak one — would both ship the same feature, passing the same acceptance, without messaging you once?** If either would need to ask, the spec — not the model — is what's underpowered.
