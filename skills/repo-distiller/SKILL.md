---
name: repo-distiller
description: Distills an entire repository into a compact Markdown knowledge base (.distill/) that AI agents read to understand the project in seconds at minimal token cost. Use this skill whenever the user asks to map, distill, condense, summarize, index, or document a codebase for agent/LLM consumption, to onboard agents onto a large or unfamiliar repo, to create a "token-efficient" project map, to generate INDEX/MAP/INSIGHTS files, or to refresh a stale distillation after code changes — even if they don't say "distill" explicitly. The output exploits file structure itself (names, nesting, proximity, ordering) as a compression layer, with MAP.md as the self-describing decompression key and INSIGHTS.md for emergent cross-file knowledge.
---

# Repo Distiller

Produce `.distill/` — a lossy-but-recoverable compression of a repository's knowledge. A consuming agent reads `INDEX.md` in ~30 seconds, drills into `MAP.md` and module files only as needed, and jumps to source via anchors. Target corpus size: **≈1–3% of the repo's token mass** (soft cap ~10k tokens total; see Monorepos for scaling).

The mindset: you are not writing documentation for humans. You are designing a **codec** — a compression scheme plus its decoder manual — whose decompressor is another LLM.

## Codec theory — internalize before distilling

1. **Structure is free information.** Paths, names, nesting, ordering and co-location carry meaning at near-zero marginal token cost: `modules/auth/session.md` already says "auth → session" without spending a sentence on it. Encode taxonomy in directory layout, relatedness in proximity, importance in ordering (first = most load-bearing). Never write prose that restates what a path already states.
2. **MAP.md is the codebook.** The distillation is compressed; MAP.md is its self-describing header. After reading MAP.md alone, any agent must be able to decode every other file: the notation, the layout semantics, the reading order, the recovery procedure. If something can't be decoded from MAP.md, the codec is broken.
3. **You design the codec.** No fixed notation is imposed by this skill. Invent the densest scheme that fits *this* repo — its language, architecture, domain — then declare it in MAP.md. A starter notation is provided below; adapt or replace it freely. The only contract: everything must be decodable from MAP.md.
4. **Telegraphic, machine-first prose.** Fragments, tables, symbols. No transitions, no narrative, no hedging filler. `auth → db.users RW !rate-limited` beats a paragraph, because the reader is a model, not a person.
5. **Reference, never reproduce.** Do not paste code. Anchor it: `src/auth/session.ts#refreshToken`. The source tree is the lossless tier; the distillation is an index into it. Anchors make the compression *recoverable*.
6. **One fact, one place.** INDEX doesn't repeat modules; modules don't repeat INSIGHTS. Duplication is token debt and a staleness liability.
7. **Depth ∝ importance, not size.** A 200-line core contract may deserve more tokens than 20k lines of generated code (which deserves exactly one line: `[gen] do not edit`).
8. **Mark inference.** Verified facts are bare; guesses carry `?`. Never launder a guess into a fact — a wrong "fact" in the distillation poisons every downstream agent.

## Output layout

```
.distill/
├── INDEX.md        # L0 entry point — always read first; ≤300 tokens
├── MAP.md          # the codebook: notation, layout semantics, reading order, fingerprint
├── INSIGHTS.md     # emergent, non-local knowledge (spec below)
├── CONVENTIONS.md  # optional: only if the repo has non-obvious norms agents must mimic
├── modules/        # L1: one file per cohesive unit; paths mirror semantics
│   ├── <area>.md
│   └── <area>/<sub>.md     # split only when an area exceeds its token budget
└── flows/          # L2 optional: cross-cutting runtime paths (request lifecycle, data pipeline, build)
```

Module granularity follows *semantic* cohesion, not necessarily folder layout — but when the repo's folders are already semantic, mirror them (it's the cheapest possible codec). `modules/` captures static structure; `flows/` captures dynamics — create flow files only when a runtime path crosses ≥3 modules and would otherwise require an agent to reconstruct it by reading all of them.

## Workflow

### 0 · Survey — never read everything

- Topology first: `tree -L 3` (or `find` + counts), file sizes, languages, generated/vendored dirs to exclude.
- Locate load-bearing artifacts: entry points, manifests (`package.json`, `pyproject.toml`, `go.mod`…), configs, CI, schemas/migrations, public API definitions.
- Reuse prior compression: README, `docs/`, ADRs, existing `CLAUDE.md`/`AGENTS.md` — someone already paid tokens to write these; harvest, verify, don't re-derive.
- Git signals when available: `git log --format= --name-only | sort | uniq -c | sort -rn | head -30` → churn hotspots; recent commit subjects → active fronts.

### 1 · Prioritize — budget by load-bearing-ness

Rank: public contracts/APIs > entry points > core domain logic > persistence/schema > config/infra > leaf utilities > generated/vendored (≈1 line each). Useful heuristics: import in-degree (what everything depends on), churn, naming centrality. Allocate the token budget by rank, not by line count — this is what makes the compression intelligent rather than proportional.

### 2 · Design the codec → write MAP.md FIRST

Decide module granularity, notation, the per-module template, and the anchor format — then write MAP.md before distilling anything. Writing the codebook first disciplines every file that follows; it is the contract you hold yourself to.

MAP.md must contain:

- **Legend** — every symbol/abbreviation used anywhere in `.distill/`.
- **Layout semantics** — what each directory and file kind means; how naming encodes meaning; what ordering signifies.
- **Reading order by intent** — e.g. "understand the project" → INDEX only; "modify feature X" → INDEX → modules/X → anchors; "debug Y" → flows/Y → modules.
- **Recovery procedure** — anchor syntax and how to jump to source; what to do when the fingerprint is stale (trust source over distillation, flag for refresh).
- **Fingerprint** — commit hash, generation date, distiller model.

Starter notation (adapt, extend, or replace — then declare your final version in MAP.md):

| token | meaning |
|---|---|
| `→` / `←` | depends on / is consumed by |
| `⇄` | mutually coupled |
| `!` | critical — dangerous to touch casually |
| `?` | inferred, unverified |
| `~` | mostly true, has exceptions |
| `[hot]` | high churn area |
| `[gen]` | generated — never edit |
| `path#symbol` | source anchor |

### 3 · Distill modules

Read strategically: exports, signatures, type definitions, docstrings and top-of-file comments before implementations. Open function bodies only for load-bearing logic.

Per-module template (adapt it, then declare the final shape in MAP.md):

```
# <name> — purpose in ≤1 line
deps: → x, y | ← z
surface: the functions/types/endpoints that matter, anchored
state: what it owns (tables, files, caches, globals)
invariants: rules that must hold locally
gotchas: non-obvious local behavior
anchors: path#symbol list for drill-down
```

Worked example of the register, not the format:

```
# payments — orchestrates charge lifecycle, Stripe-backed
deps: → core/money, db/ledger | ← api/checkout, jobs/retry
surface: charge() src/payments/charge.ts#charge · refund() #refund · webhook src/payments/hooks.ts#stripeWebhook
state: ledger table (append-only !), idempotency keys in redis (TTL 24h)
invariants: every mutation writes ledger first; amounts are integer cents (core/money), never float
gotchas: webhook retries arrive out of order ~ handled by event version check #applyEvent
anchors: src/payments/charge.ts · src/payments/hooks.ts · db/migrations/014_ledger.sql
```

Hard budget: **≤400 tokens per module file**. Over budget → raise the abstraction level or split into `<area>/<sub>.md`. Resist the urge to be complete; be *load-bearing*.

### 4 · Extract INSIGHTS.md — emergent knowledge only

**Admission test (non-locality):** if reading any single file would teach it, it belongs in that module's file — not here. INSIGHTS.md holds only knowledge that lives *between* files: what a senior engineer tells you during onboarding and no file states. This is the highest-value file in the corpus because it is the only one the source code cannot regenerate.

Sections (omit any that are empty — boilerplate is anti-signal):

1. **Mental model** — the 1–3 abstractions that make the whole system click ("treat X as an event log folded into projections"). If a new agent absorbs only this section, it should stop being surprised by the architecture.
2. **Global invariants** — cross-cutting rules, enforced or merely assumed ("UI never imports persistence; everything crosses `core/ports`").
3. **Hidden couplings** — change-here-breaks-there links invisible to import graphs: shared formats, ordering assumptions, timing, env vars, magic strings.
4. **Rationale & rejected paths** — why it is the way it is; tradeoffs taken; approaches tried and abandoned (mine comments, ADRs, git history). Prevents agents from re-proposing dead ends.
5. **Scars** — weird code, explained: workarounds, legacy compat, vendored hacks. Protects intentional ugliness from being "fixed" by a well-meaning agent.
6. **Danger zones** — where plausible-looking edits cause subtle breakage; the explicit "never do" list.
7. **Lies** — where names, comments, or docs diverge from actual behavior (`getUser` also mutates last_seen; README's setup steps are stale). Highest value-per-token section: it corrects the false priors an agent forms by reading the code at face value.
8. **Unknowns `?`** — questions the distiller could not resolve. Declaring ignorance is cheaper than a downstream agent discovering it mid-task.

Every entry: 1–3 lines, anchored to evidence where possible, `?` when inferred. Budget: **≤800 tokens**.

### 5 · Write INDEX.md last (L0)

≤300 tokens. It is the L0 of progressive disclosure — written last because it summarizes everything, read first by every consumer. Contents:

- What the project is — 1–2 lines.
- Stack — one line.
- Run / test / build — commands, anchored to their definitions.
- Architecture — ≤5 lines or one small ASCII diagram.
- **"Where to go" table** — intent → `.distill/` file → source anchor. This table is the router that makes the whole corpus navigable.

INDEX.md must orient a fresh agent in ~30 seconds and tell it where to spend its next tokens.

### 6 · Verify & fingerprint

- **Self-test:** write 5–10 realistic agent tasks ("add a field to X", "why does Y retry twice?", "where is auth enforced?"). Answer each using **only** `.distill/`. Wherever the corpus fails, fix the corpus — not the answer. This converts vibes into a falsifiable quality check.
- Stamp every file with frontmatter: `commit`, `generated`, `model`.
- **Discovery is part of the deliverable:** if the repo has `CLAUDE.md` / `AGENTS.md` / equivalent, add one line pointing to `.distill/INDEX.md` as the first read. A distillation no agent finds is worth zero.

## Maintenance — incremental refresh

1. `git diff --stat <fingerprint>..HEAD` → list touched areas.
2. Re-distill only the affected module files; then audit INSIGHTS.md and INDEX.md for claims the diff invalidated.
3. Re-run the self-test questions that touch changed areas; update fingerprints.

Never regenerate the whole corpus for a small diff. Stability of the distillation is itself information — diffs of `.distill/` over time show *knowledge drift*, which is reviewable in PRs like any other artifact.

## Monorepos & very large repos

Distill fractally: each package gets its own `.distill/` following this same spec; the root `.distill/INDEX.md` becomes a router with one line per package index. Keep every individual corpus within budget — let *depth* absorb scale, never file size.

## Quality bar

Reject in review:
- Human-documentation prose; restating what paths already say; pasted code blocks.
- Uniform depth regardless of importance; empty boilerplate sections; unverifiable claims without `?`.

Require in review:
- Tables, fragments, symbols; depth ∝ importance; every claim anchored or trivially checkable; MAP.md alone sufficient to decode the corpus; total ≈1–3% of repo tokens.

Final check before delivering: **could a fresh agent, reading only INDEX.md + MAP.md, navigate to the right file for any plausible task in ≤3 hops?** If not, the codec — not the agent — is what needs fixing.
