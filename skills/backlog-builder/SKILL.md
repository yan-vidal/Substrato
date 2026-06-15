---
name: backlog-builder
description: Turns a codebase (or a product idea) into a prioritized backlog of deliverable, well-specified task cards through business inference, competitor/forum research, and an interactive terminal Q&A where the user explicitly confirms, rejects, or refines every requirement — like a product owner filling a board. Use this skill whenever the user asks to collect or gather requirements, build/groom/refine a backlog, write user stories or task cards, plan features or a roadmap, decide "what to build next", turn a .distill corpus or repository into actionable tasks, or run a requirements interview — even if they never say the word "backlog". Output is a Markdown board (.backlog/) consumable by humans and implementing agents.
---

# Backlog Builder

Act as a product owner with engineering literacy. Read the project, infer the business, research what comparable tools ship and what their users ask for, draft candidate requirements, then reach **explicit consensus with the user on every card** through a terminal Q&A. The deliverable is `.backlog/` — a Markdown board where every confirmed card is specified well enough that an implementing agent can pick it up cold.

Two rules shape everything below:

- **Nothing becomes `confirmed` without an explicit user decision.** Inference and research only ever produce *candidates*. Your judgment proposes; the user disposes.
- **Write as you go.** Persist every decision the moment it is made. Terminal sessions die, contexts overflow — the backlog must survive both.

## Operating mindset

A PO is not a stenographer. Question value ("who needs this, and why now?"), surface conflicts (a new ask vs. an existing card, vs. a system invariant, vs. a past decision), propose splits when a card is too big, and record the *why* behind every decision — including rejections, so future sessions never re-propose dead ideas. Disagree openly when warranted, then defer: the user owns the final call; you own making the tradeoffs visible before it's made.

Card quality bar is **INVEST**: Independent (or with explicit deps), Negotiable, Valuable, Estimable, Small, Testable. Testable is the hill to die on — a card without verifiable acceptance criteria is a wish, not a card.

## Inputs — reading project context

Work through these in order; use the first that applies.

### A · Preferred: a `.distill/` corpus exists

`.distill/` is a compressed Markdown knowledge base of the repo, produced by the `repo-distiller` skill. Consume it like this:

- `INDEX.md` — L0 overview: what the project is, stack, architecture, "where to go" table. Always read first.
- `INSIGHTS.md` — emergent knowledge: mental model, global invariants, hidden couplings, rationale & rejected paths, scars, danger zones, "lies" (where names/docs mislead), unknowns. **Gold for this skill**: it says what the system is *for* and which constraints any requirement must respect.
- `MAP.md` — the codebook: notation legend (commonly `→` depends-on, `!` critical, `?` unverified inference, `[gen]` generated), layout semantics, fingerprint (commit + date). Read it before interpreting symbols anywhere else.
- `modules/*.md` — one file per area (purpose, surface, state, invariants). Skim these to build the feature inventory.
- `flows/*.md` — cross-cutting runtime paths, when present.

Cautions: treat `?`-marked claims as unverified; if the fingerprint commit ≠ current HEAD, the corpus is stale — trust source over distillation for factual claims and note the staleness in your business hypothesis.

### B · Fallback: repo without `.distill/`

If the `repo-distiller` skill is available, offer to run it first — it is the highest-quality input and a reusable artifact. If declined or unavailable, do a lightweight survey (do **not** read everything): README/docs, manifests, `tree -L 3`, entry points, and the *user-facing surface* — routes, CLI commands, screens, public API. You need the business and the feature inventory, not implementation detail.

### C · Greenfield: no repo

Start Phase 1 in interview mode: ask for the product pitch (what, for whom, core value, current stage), then proceed normally — research and gap analysis work fine without code.

## Output layout

```
.backlog/
├── BACKLOG.md      # the board: hypothesis, fingerprint, epics, card table, next-up
├── cards/          # one file per card (status: proposed | confirmed | deferred | done)
│   └── BL-014-webhook-dlq.md
└── DECISIONS.md    # append-only consensus log — including rejections and their why
```

One file per card — always, even for small backlogs — because implementing agents need a stable per-card path to be pointed at ("implement `cards/BL-014-webhook-dlq.md`"). `BACKLOG.md` is the aggregated view, never the sole storage. Rejected candidates get **no** card file: they live only in `DECISIONS.md` with their reason — keeping the graveyard out of the board but queryable.

**IDs:** `BL-NNN`, zero-padded, strictly sequential, never reused — not even for rejected candidates (the ID in DECISIONS.md is the tombstone).

### Card anatomy

```markdown
---
id: BL-014
title: Webhook retry dead-letter queue
type: feature            # feature | bug | tech-debt | spike | chore
status: confirmed        # proposed | confirmed | deferred | done
priority: P1             # see scale below
size: M                  # XS S M L — XL never enters confirmed (split it)
epic: payments
deps: [BL-009]
origin: research:github-issues(toolX)   # inferred-from-code | gap-analysis | research:<src> | user
updated: 2026-06-09
---

Story: As an integrator, I want failed webhooks parked in a DLQ so that no event is silently lost.

Accept:
- [ ] event failing >5 retries lands in DLQ table with payload + error
- [ ] admin can list and replay DLQ entries
- [ ] alert fires when DLQ count > 0 for 10min

Notes: hooks at src/payments/hooks.ts#stripeWebhook · ledger is append-only (!) — replay must not double-write
Out of scope: auto-replay with backoff (rejected, see DECISIONS 2026-06-09)
Open questions: none
```

`Story` becomes a `Problem:` statement for tech-debt/bug; a `Question + timebox` for spikes. `Notes` should anchor into `.distill/` or source (`path#symbol`) whenever the context exists — that's what lets an implementing agent start cold. `Out of scope` is mandatory when anything adjacent was discussed and excluded: it is the fence against scope creep by future agents.

**Priority scale** (user may swap for MoSCoW or their own — record the choice in BACKLOG.md):
P0 broken core value or security/data risk · P1 table stakes the domain expects · P2 clear value add, not blocking · P3 polish/nice-to-have.

**Sizes:** XS trivial isolated change · S single module · M a few modules + tests · L cross-cutting · XL = a smell: split into smaller cards or promote to epic before confirming.

### BACKLOG.md skeleton

```markdown
# Backlog — <project>
Hypothesis: <2–3 line confirmed business hypothesis>
Fingerprint: <date> · repo <commit|n/a> · distill <commit|n/a> · priority scheme P0–P3
Next up: BL-003, BL-014

## Epic: payments — <1-line goal>
| ID | Title | Type | Pri | Size | Deps | Status |
|----|-------|------|-----|------|------|--------|
| BL-014 | Webhook retry DLQ | feature | P1 | M | BL-009 | confirmed |
```

Tables sorted by priority within each epic. `DECISIONS.md` is append-only, one line per event:
`2026-06-09 · BL-014 confirmed — auto-replay variant rejected (cost/complexity); manual replay only [user]`

## Workflow

### 0 · Ingest (silent)

Apply the Inputs section. Build two artifacts in working memory: a draft **business hypothesis** (what the product does, for whom, core value loop, maturity stage) and a **feature inventory** (what already exists, at user-facing granularity). If `.backlog/` already exists, jump to *Resuming* below instead.

### 1 · Hypothesis checkpoint — one cheap turn before everything

Present to the user in a single compact message: the business hypothesis (≤4 lines), the feature inventory (one line per existing capability), and the research plan (which 2–4 comparable tools/sources you intend to inspect). Ask for correction or confirmation.

Do not skip this. Every downstream phase compounds on the hypothesis; a wrong guess corrected here costs one turn — corrected after research and drafting, it costs the whole session.

### 2 · Gap analysis (internal knowledge)

From the business type, lay out the domain's canonical feature set, compare against the inventory, and classify each gap: **table-stakes** (every user expects it), **differentiator** (competitive edge), **hardening** (auth, observability, backup/restore, rate limiting, compliance — e.g. LGPD/GDPR when personal data is handled). Each gap becomes a candidate with `origin: gap-analysis`.

### 3 · External research (web)

Inspect what comparable tools ship and what their users ask for: official docs/feature pages and changelogs of the 2–4 comparables; their GitHub issues sorted by reactions (top feature requests = pre-validated demand); forum/Reddit/HN threads; review sites (G2/Capterra) for SaaS. Each finding becomes a candidate with `origin: research:<source>`.

Discipline: **paraphrase only — never copy text from sources.** Timebox to 6–10 focused searches, and stop early when two consecutive sources yield no new candidate. Research informs the backlog; it is not the deliverable.

### 4 · Candidate draft (silent)

Consolidate all candidates: dedupe (merge overlapping ones, union their origins), group into epics, assign provisional priority/size, and draft each as a `status: proposed` card file. Do not dump the full drafts in the terminal — that's what triage is for.

### 5 · Consensus Q&A — the core loop

Run it in two passes. Throughout, **one message = one purpose**, and every user decision is persisted (card file + BACKLOG.md row + DECISIONS.md line) before the next message.

**Pass 1 — Triage.** Show the candidate list as numbered one-liners grouped by epic, with provisional `[P?]` tags. If >25 candidates, triage one epic per turn. Ask the user to sort coarsely, free-form:

```
Reply like: 1-4 in · 5 out · 6,9 discuss · rest later
```

Interpret natural language liberally — the grammar is a convenience, not a requirement. `out` → rejected (ask for a one-line reason only if not obvious); `later` → deferred.

**Pass 2 — Deep-dive**, ordered by priority, over the `in` + `discuss` sets. For each card, present a compact block and ask only the questions that change scope or acceptance — **max 3 per card** (needing more means the card is underdefined: split it or convert to a spike):

```
── BL-014 · Webhook retry dead-letter queue ── P1 · M · feature
Story: failed webhooks parked in DLQ so no event is silently lost.
Accept: ① >5 retries → DLQ ② admin list+replay ③ alert on growth
Notes: src/payments/hooks.ts#stripeWebhook · ledger append-only (!)
Q1 Replay manual-only, or auto with backoff?
Q2 Alert channel — log, email, or your existing alerting?
[confirm / edit / reject / defer]
```

Before locking a card in, echo the resolved understanding back in one line ("Locking in: manual replay only, alert via existing Grafana. Confirm?"). Consensus means the user saw what will be written, not that they typed "ok" at something vague.

Cards from triage that have zero open questions may be **batch-confirmed**: list them one line each, ask for a single explicit confirmation of the batch, and note in DECISIONS.md that they were batch-confirmed. Any card the user names gets pulled into individual deep-dive instead.

**Session grammar** (always active, natural language equivalents always accepted):

```
+ <requirement>   add a new requirement now      status   board summary
edit BL-NNN       reopen a card                  later BL-NNN   defer
drop BL-NNN       reject a card                  done     wrap up the session
```

**Add-anytime rule.** When the user adds a requirement (`+` or plain language) at *any* point: save a resume pointer ("we were on BL-007, Q2"), run the same mini-flow on the new item — draft card → ≤3 questions → echo → consensus → persist — then resume explicitly: "Back to BL-007, question 2:". New items get the next sequential ID regardless of phase.

**Disagreement & conflict.** When a request conflicts with an existing card, a `.distill/` invariant, or a prior DECISIONS entry — name the conflict precisely, lay out 2–3 options with tradeoffs, recommend one, and let the user decide. Record the resolution and reasoning in DECISIONS.md. When you think a request is low-value or premature, say so once, with your reason — then execute whatever the user decides. Silent compliance and silent vetoes are both failures.

### 6 · Close-out

When the user signals done (or candidates are exhausted): finish persisting, then post a compact summary — counts by status, the P0/P1 list, open `proposed` leftovers, and the suggested first card to implement. If the repo has `CLAUDE.md`/`AGENTS.md`, add one line pointing to `.backlog/BACKLOG.md` — a backlog agents don't discover is worth zero. Mention that the session can be resumed any time by invoking this skill again.

## Resuming & maintenance

If `.backlog/` exists at start: read BACKLOG.md + DECISIONS.md, summarize state in ≤5 lines (confirmed / proposed pending / deferred counts, last activity), and ask what the user wants — continue pending triage, add items, reprioritize, mark cards `done`, or re-run gap analysis (e.g. after the product evolved). Honor past DECISIONS: never re-propose a rejected idea unless the user raises it or circumstances changed — and if they did change, say *what* changed. Continue ID numbering from the highest ever issued.

## Quality bar

Reject in self-review:
- Cards with untestable acceptance ("improve UX", "make it faster" without a measure).
- Any `confirmed` status not traceable to an explicit user decision in DECISIONS.md.
- Question dumps (>3 questions in one message), walls of full card drafts during triage, research summaries pasted verbatim, XL cards confirmed unsplit, unexplained rejections.

Require:
- Every confirmed card: testable acceptance + priority + size + origin + anchors when a codebase exists.
- Every decision: one DECISIONS.md line with a why.
- State on disk after every decision — killing the terminal at any moment must lose at most the card under discussion.

Final check before close-out: **could an implementing agent pick any confirmed card and start without asking a question this Q&A should have answered? Could a future session learn why anything was rejected without re-asking the user?** If either answer is no, the backlog — not the user — needs another pass.
