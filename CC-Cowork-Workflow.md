# CC-Cowork-Workflow — Claude Code external executor (Codex) orchestration

**Scope:** Claude Code only. Depends on the `/codex:*` plugin, which other agents (Cursor, standalone CLIs, …) do not have. Kept out of `AGENTS.md` / `.trellis/` on purpose — those are tool-neutral. `CLAUDE.md` only points here and says *when* to load this file; the rules live here so they don't sit in every-session context.

An **external executor** is a delegated coding/review backend (currently **Codex**). The rules below are written executor-neutral, so another backend could be slotted in later by swapping the companion path and command prefix.

## Executors

| Executor | Plugin | Companion runtime (`<companion>`) | Auth | Cmd prefix |
| --- | --- | --- | --- | --- |
| **Codex** (GPT-5) | `codex-plugin-cc` (official) | `.../plugins/cache/openai-codex/codex/<ver>/scripts/codex-companion.mjs` | ChatGPT subscription | `/codex:*` |

> The companion path contains a version segment (`<ver>`); if it has changed, the path printed by `/codex:setup` is authoritative.

## Roles

- **Claude orchestrates** the full Trellis task lifecycle: `create → brainstorm → start → check → finish`. Claude is always the driver. Never let an executor be the entry point — a cold `/codex:rescue "<task>"` with no open task bypasses Trellis and is not allowed.
- **The executor executes** only inside the `in_progress` (implementation) phase, on a single, well-defined unit handed to it.
- **Reviewer ≠ author.** Whoever did not write the code reviews it. Executor writes → Claude reviews the returned diff. Claude writes → delegate the review to the executor (`/codex:review`; add `:adversarial-review` for business-invariant or concurrency code).

## Flow

1. `task.py create "<title>"` — open the task (planning).
2. `trellis-brainstorm` → write `prd.md`.
3. **After the PRD is written, summarize it in Chinese for the user** so they know exactly what is planned, then get explicit approval. This Chinese PRD summary is the user's approval gate — **do not run `task.py start` until the user approves it.**
4. `task.py start <task-dir>` — enter `in_progress`.
5. Delegate one defined unit to an executor via its **companion background-job runtime, driven from the main session (plain Bash) — NOT the synchronous `*:rescue` Agent subagent.** (The subagent wrapper blocks for the entire run, then makes one heavy uncached Anthropic call to summarize; if that final call hits a 529/overload the whole report is lost even though the executor already finished and stored the result. Observed: a 1m34s Codex job reported as a 348s `529 Overloaded` Agent failure. Running the companion directly from main-session Bash has no second Anthropic call, so it is immune.) Use the job interface:
   - Start (non-blocking): `node <companion> task --background [--write] [--model gpt-5.5] [--effort xhigh] [--prompt-file <file>] "<prompt>"` → returns a job-id immediately. Use `--prompt-file` for long structured prompts (write it into the task dir first); `--model gpt-5.5 --effort xhigh` is the strong setting for reviews.
   - Poll + auto-fallback (see the section below) — do NOT hand-poll turn by turn.
   - Fetch: `node <companion> result <job-id> --json` when done → the review text is at `storedJob.result.rawOutput`.
   - The delegation prompt **must carry the relevant `.trellis/spec/**` context inline** — executor sub-agents cannot inherit the parent session's task context, so unfed context is lost.
   - **On any error or apparent failure, run `node <companion> status --all` FIRST, before any retry** — the job and its result are almost certainly already stored. A rescue error ≠ work not done; never blindly re-delegate (that risks double-applying).
6. Claude reviews the returned diff **and** runs `trellis-check` (deterministic gate: lint / type / test / spec Verification). Fail → return to step 5 (executor re-work) or fix directly; pass → step 7.
7. `trellis:finish-work` — archive.

## Auto-injection: background job + auto-fallback poller (proven)

The "fire a Codex job and have its result surface back to you automatically" loop — used both per implementation unit and for whole-PRD / whole-feature reviews:

1. **Launch** from main-session Bash (non-blocking): `node <companion> task --background --model gpt-5.5 --effort xhigh --prompt-file <task-dir>/codex-...-prompt.md` → prints a job-id.
2. **Auto-fallback poller** — a single `run_in_background: true` Bash loop, so the harness re-invokes you the moment it exits. It polls `node <companion> status <job> --json`, and **on completion fetches the result, writes it to `<task-dir>/codex-...-result.txt`, then exits** → job-exit = harness notification = you read the file. No turn-by-turn babysitting.
   - **Gotcha (cost a real bug):** the status field is **`job.status`, NESTED under `job`** — not top-level `status`. Parsing top-level made the poller spin forever and the completion never surfaced ("looks like it never finished"). Parse `d['job']['status']`.
   - Persist every `codex-*-result.txt` (and the `*-prompt.md`, the captured `*.diff`) in the task dir — provenance + crash-safe resume.

### Recovery when the result seems "gone"
- Codex jobs run on the Codex side and survive Claude quota/session limits — but the **companion job store is wiped on session restart / quota reset**, so `status --all` may show *no jobs*. The full Codex turn is still on disk at `~/.codex/sessions/<YYYY>/<MM>/<DD>/rollout-*.jsonl`. Find the right one by grepping a UNIQUE phrase from your prompt; extract the answer from `payload.role == "assistant"` events (concatenate their `content[].text`).
- A job **killed mid-run** (session exited while it was working) leaves only intermediate narration, never a final structured verdict — **re-launch a fresh review** rather than trusting the partial.

## Two proven review flows (Claude authors → Codex reviews; author ≠ reviewer)

Both apply to any non-trivial feature:

- **PRD review (planning phase, before any code):** Claude writes `prd.md`, then hands the PRD + a discussion summary to Codex (`gpt-5.5 xhigh`) for a security / architecture / feasibility pass. Iterate the PRD across rounds until **0 blockers**, *then* `task.py start`. Author≠reviewer applies to the design, not just the code.
- **Per-unit code review + 精修:** split the build into small units/PRs; each unit = `trellis-implement` (Claude/Opus authors) → `trellis-check` (deterministic gate) → **Codex adversarial review of that unit's diff** → Claude triages findings (real blocker vs deferred-by-plan) and fixes (精修), then **independently re-reads the critical diff** (never trust the sub-agent's "done" blindly). Run **one whole-feature final review** (security + PRD-compliance + acceptance-criteria checklist) before the final commit.

## Non-negotiables

- Never wave through the review/quality gate just because the executor "looks done." Executors write to disk directly, so Claude's review must be a real read of the diff — especially for business invariants and concurrency-sensitive code.
- Treat any executor's *research/claims* (not just its code) as signal, not ground truth — verify load-bearing facts (repo names, install commands, shutdown dates, `file:line` refs) with a deterministic check before acting. Decorrelated ≠ correct.
- Keep these rules in this file under repo root, pointed to from `CLAUDE.md`. Do not migrate them into `AGENTS.md` or `.trellis/` — they are Claude-Code-only by nature.
