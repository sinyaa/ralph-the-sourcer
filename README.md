# Recruiter Ralph

> "Me fail sourcing? That's unpossible."

An autonomous AI sourcing pipeline built on the [Ralph Wiggum technique](https://ghuntley.com/ralph/) by [@GeoffreyHuntley](https://github.com/ghuntley/how-to-ralph-wiggum) — except instead of writing software, Ralph is now loose in the talent market with a clipboard and a dream.

The original Ralph stumbles through codebases, shipping features through sheer persistence and iterative self-correction. Recruiter Ralph does the same thing, but to people. He reads a job description, asks himself questions a hiring manager would ask, answers them himself, builds a scoring rubric, and then scours the internet for real humans — all while you go get coffee.

He is deterministically awkward in an undeterministic hiring market. And somehow, it works.

## Prerequisites

Ralph is needy. He requires:

- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** — installed and authenticated.
- **Anthropic API key** with access to **Claude Opus** (Ralph refuses to think small).
- **Windows** — `loop.bat` is a batch file. Mac/Linux users will need to adapt it to a shell script (or submit a PR — Ralph welcomes collaboration).

## Quick Start

```
git clone https://github.com/YOUR_USERNAME/ralph-the-sourcer.git
cd ralph-the-sourcer
```

1. **Write your job description** — Replace `Job_requirements.md` with the role you're hiring for. Be specific. Ralph takes you literally.
2. **Run Ralph:**
   ```
   loop.bat
   ```
3. **Go get coffee.** Ralph handles the rest — analyzing the role, building a scoring rubric, searching the web for real candidates, scoring them, and writing personalized outreach messages. Everything lands in `candidates.csv`.

That's it. One command. Ralph takes it from there.

## How It Works

### Phase 1: Ralph Reads the Job Description

Ralph ingests `Job_requirements.md` and — like a recruiter who just finished a LinkedIn Learning course — generates 10-20 sharp questions a hiring manager should answer. Then, because no hiring manager is present, Ralph answers them himself. With confidence ratings. He is nothing if not self-assured.

### Phase 2: Ralph Makes a Plan

Ralph reads his own answers, nods approvingly, and synthesizes them into a scoring rubric, an ideal candidate profile, and 10-15 search vectors. He writes it all to `CANDIDATE_SEARCH_PLAN.md` and cracks his knuckles.

### Phase 3: Ralph Searches the Internet for People

Ralph deploys up to 20 parallel subagents to fan out across the web, hunting for real humans who match the role. Each candidate is scored on five dimensions, validated against the job requirements, deduped, and written to `candidates.csv`. Every iteration, Ralph re-evaluates the entire pool — raising the bar as he goes, enforcing concentration limits, and filling skill gaps.

Then — and this is where it gets personal — Ralph writes a tailored outreach message for each new candidate. Under 200 words. No "exciting opportunity" fluff. He references their actual work — a paper they wrote, a system they built, a talk they gave — and connects it to the specific parts of the role that would make them care. Stored right in `candidates.csv` in the `OutreachMessage` column, ready to copy-paste into whatever channel you use to cold-message strangers about their career.

He does this N times, or until you hit Ctrl+C, whichever comes first.

## Agent Architecture

The pipeline is a three-step autonomous agent driven by `loop.bat` — a multi-agent AI recruiting system orchestrated by a 139-line batch file, because why not. The entire framework is zero-dependency by design: no Python, no Node, no package manager, no virtual environment. If you have Claude Code installed and a Windows machine, you can run it out of the box. Each step pipes a prompt file into Claude Code, which reads project files, spawns subagents, and writes structured output.

```
┌─────────────────────────────────────────────────────────┐
│                   loop.bat [N] [T]                       │
│                                                         │
│  Step 1: PREPARE PASS 1 ──► CANDIDATE_SEARCH_PLAN.md    │
│  Step 2: PREPARE PASS 2 ──► CANDIDATE_SEARCH_PLAN.md    │
│  Step 3: SEARCH (×N) ──────► candidates.csv             │
│                               CANDIDATE_SEARCH_PLAN.md  │
└─────────────────────────────────────────────────────────┘
```

### Step 1: Prepare Pass 1 — Analyze Role & Generate Questions

| Parameter | Value |
|-----------|-------|
| Prompt | `PROMPT_PREPARE.md` |
| Model | Claude Opus |
| Subagents | Up to 10 Sonnet subagents (web research) |
| Input | `Job_requirements.md` |
| Output | `CANDIDATE_SEARCH_PLAN.md` (with "Questions for Hiring Manager" section) |
| State trigger | Runs when `CANDIDATE_SEARCH_PLAN.md` has **no** "Questions for Hiring Manager" section |

Ralph reads the job description and decomposes the role: required vs preferred skills, seniority level, technical domain, peer companies, and relevant communities. He deploys up to 10 parallel Sonnet subagents to research the role's domain via web search. Then he generates 10-20 sharp questions a hiring manager should answer — covering role clarity, candidate profile, practical constraints, and search strategy. Since no hiring manager is present, Ralph answers each question himself with a confidence rating (HIGH / MEDIUM / LOW). The output is written to `CANDIDATE_SEARCH_PLAN.md` and the step halts.

### Step 2: Prepare Pass 2 — Refine Plan & Build Rubric

| Parameter | Value |
|-----------|-------|
| Prompt | `PROMPT_PREPARE.md` (same prompt, different behavior via state detection) |
| Model | Claude Opus |
| Subagents | Opus subagent (synthesis) + up to 10 Sonnet subagents (web research) |
| Input | `Job_requirements.md`, `CANDIDATE_SEARCH_PLAN.md` (Pass 1 output) |
| Output | `CANDIDATE_SEARCH_PLAN.md` (rewritten: rubric, profile, search vectors) |
| State trigger | Runs when `CANDIDATE_SEARCH_PLAN.md` **has** a "Questions for Hiring Manager" section |

Ralph reads his own Q&A, weights HIGH-confidence answers heavily, and hedges on LOW-confidence answers by casting a wider search net. He produces:

- **Ideal Candidate Profile** — 2-3 paragraph archetype: career arc, title range, likely employers, expected public footprint.
- **Scoring Rubric** — role-specific definitions for each of the five scoring dimensions (SkillsMatch, ExperienceDepth, DomainCredibility, LeadershipSignal, AvailabilitySignal), with concrete 1-3, 4-6, and 7-10 band descriptions.
- **Search Vectors** — 10-15 concrete vectors, each with a label, 2-3 web queries, confirmation signals, yield estimate, and priority order.
- **Key Assumptions** — LOW-confidence answers the search should hedge around.

The Pass 1 content is replaced entirely. The plan is kept under 150 lines.

### Step 3: Search — Find, Score, Validate & Outreach (×N iterations)

| Parameter | Value |
|-----------|-------|
| Prompt | `PROMPT_SOURCE.md` |
| Model | Claude Opus |
| Subagents | Up to 20 Sonnet subagents (parallel web search + candidate verification) |
| Input | `AGENTS.md`, `Job_requirements.md`, `CANDIDATE_SEARCH_PLAN.md`, `candidates.csv` |
| Output | `candidates.csv` (updated), `CANDIDATE_SEARCH_PLAN.md` (progress/gaps updated) |
| Iterations | Configurable via `loop.bat` first argument (default: 5) |
| Pool cap | 50 candidates max |

Each iteration follows a strict sequence:

1. **Search** — Deploy up to 20 parallel Sonnet subagents across 2+ new search vectors. Vectors rotate through skill keywords, target companies, communities (conference speakers, OSS contributors), similar role titles, and geography.
2. **Score** — Every candidate is evaluated on 5 weighted dimensions using the rubric from `CANDIDATE_SEARCH_PLAN.md`.
3. **Validate (loopback)** — Mandatory 6-step validation pass enforced by `AGENTS.md`:
   - Re-score all candidates against `Job_requirements.md` via web search
   - Dedup check (merge same-person variants)
   - Threshold enforcement (escalating: 5.0 for iterations 1-3, 6.0 for 4-5, 7.0 for 6+)
   - Concentration check (no single company > 20% of pool)
   - Outreach message check (every NEW/UPGRADED candidate gets a personalized message)
   - Gap report (update `CANDIDATE_SEARCH_PLAN.md` with underrepresented skill areas)
4. **Outreach** — For each NEW or UPGRADED candidate, Ralph writes a personalized message (<200 words) referencing their actual work and connecting it to the role. Stored in the `OutreachMessage` column of `candidates.csv`.

### Pipeline Parameters

```
loop.bat             # 5 search iterations (default)
loop.bat 10          # 10 iterations (ambitious Ralph)
loop.bat 0           # unlimited (Ralph has nowhere else to be)
loop.bat 20 50       # 20 iterations, but stop early if 50 candidates found
loop.bat 0 100       # unlimited iterations, stop at 100 candidates
```

| Parameter | Default | Set via | Description |
|-----------|---------|---------|-------------|
| `search_iterations` | 5 | `loop.bat` 1st arg | Number of search iterations after the 2 prepare passes. `0` = unlimited. |
| `target_candidates` | 0 (disabled) | `loop.bat` 2nd arg | Stop early when this many candidates are in `candidates.csv`. `0` = no target. |
| Model | Claude Opus | Hardcoded in `loop.bat` | Main agent model for all 3 steps. |
| Subagent model | Claude Sonnet | Set in prompts | Used for parallel web search and candidate verification. |
| Max subagents (Prepare) | 10 | `PROMPT_PREPARE.md` | Parallel Sonnet subagents for domain research. |
| Max subagents (Search) | 20 | `PROMPT_SOURCE.md` | Parallel Sonnet subagents for candidate sourcing. |
| Pool cap | 50 | `PROMPT_SOURCE.md` | Maximum candidates in `candidates.csv` at any time. |
| Score threshold (iter 1-3) | 5.0 | `AGENTS.md` | Minimum OverallScore to remain in pool. |
| Score threshold (iter 4-5) | 6.0 | `AGENTS.md` | Escalated threshold after iteration 3. |
| Score threshold (iter 6+) | 7.0 | `AGENTS.md` | Final threshold for convergence. |
| Concentration limit | 20% | `AGENTS.md` | Max share of pool from any single company. |
| Outreach max words | 200 | `PROMPT_SOURCE.md` | Hard limit on outreach message length. |
| Permissions | `--dangerously-skip-permissions` | `loop.bat` | Allows autonomous file/web access without per-action confirmation. |
| Output format | `stream-json` | `loop.bat` | Claude Code output format flag. |

### State Detection

The prepare prompt (`PROMPT_PREPARE.md`) is called twice with the same arguments. Ralph determines which pass to execute by inspecting `CANDIDATE_SEARCH_PLAN.md`:

- **No file / no "Questions for Hiring Manager" section** → Execute Pass 1 (analyze + generate questions)
- **"Questions for Hiring Manager" section exists** → Execute Pass 2 (synthesize rubric + search vectors)

This means the pipeline is **resumable** — if interrupted after Pass 1, re-running `loop.bat` will detect the existing questions and proceed to Pass 2 rather than starting over.

## Customize for Your Role

The only file you need to change is `Job_requirements.md`. Everything else is role-agnostic.

Ralph derives his entire strategy — search vectors, scoring rubric, target companies, outreach angle — from the job description. The more specific your requirements, the sharper his search. Vague descriptions produce vague candidates. Ralph is a mirror.

When you start a new search, delete (or rename) these files so Ralph builds fresh:
- `CANDIDATE_SEARCH_PLAN.md` — Ralph regenerates this from your job description.
- `candidates.csv` — Ralph creates this during the search phase.

Leave everything else untouched: `AGENTS.md`, `PROMPT_PREPARE.md`, `PROMPT_SOURCE.md`, and `loop.bat` are the framework.

## Files

| File | What Ralph Does With It |
|------|------------------------|
| `Job_requirements.md` | Reads it. Obsessively. This is Ralph's bible. **Replace this with your role.** |
| `AGENTS.md` | Operational rules. Ralph's guardrails next to the slide. |
| `PROMPT_PREPARE.md` | The prompt that turns Ralph into a recruiting strategist. |
| `PROMPT_SOURCE.md` | The prompt that turns Ralph into a sourcing machine. |
| `CANDIDATE_SEARCH_PLAN.md` | Ralph's master plan. Rubric, vectors, progress tracking. Generated automatically. |
| `candidates.csv` | The deliverable. Real people, scored, sorted, with personalized outreach messages. Generated automatically. |
| `loop.bat` | The loop. `while :; do ralph ; done` but in batch. |

## Example Output

### candidates.csv columns

```
Name,Title,Company,Location,LinkedIn,Skills,SkillsMatch,ExperienceDepth,
DomainCredibility,LeadershipSignal,AvailabilitySignal,OverallScore,Status,
Notes,Source,LastUpdated,OutreachMessage
```

Each candidate is scored on five weighted dimensions:

| Dimension | Weight | What Ralph Looks For |
|-----------|--------|---------------------|
| SkillsMatch | 25% | Do their skills match the job requirements? |
| ExperienceDepth | 25% | Years, seniority, shipped systems at scale |
| DomainCredibility | 20% | Public artifacts — papers, repos, talks, patents |
| LeadershipSignal | 15% | Evidence of leading teams, mentoring, cross-org influence |
| AvailabilitySignal | 15% | Tenure, recent moves, "open to work" signals |

### Sample outreach message

> Your work on [specific project] — particularly [specific detail] — caught my attention. We're building [concrete aspect of the role] and your experience with [relevant skill] maps directly to the hardest problem on the roadmap. Would you be open to a 15-minute call this week to see if it's interesting?

That's the vibe. Specific. Short. No "exciting opportunity" anywhere.

## Quality Controls (Ralph Has Standards)

- Every candidate must be a real, verifiable person found via web search. Ralph does not hallucinate colleagues.
- Score thresholds escalate over iterations: 5.0 minimum early on, rising to 7.0 as Ralph gets pickier.
- No single company can represent more than 20% of the pool. Ralph believes in diversity of origin.
- Full validation pass every iteration: re-scoring, dedup, gap analysis. Ralph checks his own homework.

## Outreach (Ralph Talks to Strangers)

Every candidate in `candidates.csv` gets a personalized outreach message in the `OutreachMessage` column. Ralph writes these himself — under 200 words, referencing the candidate's actual work, connecting it to the role's most relevant responsibilities. No templates. No "Dear Hiring Prospect." Just a short, specific message that sounds like it was written by someone who actually read their profile, because Ralph did.

Messages are generated for `NEW` and `UPGRADED` candidates. `KEPT` candidates retain their existing message. `DOWNGRADED` candidates get theirs cleared, because Ralph knows when to stop texting.

## Cost and Permissions

### Ralph is not cheap

Each iteration runs **Claude Opus** as the main agent with up to **20 parallel Claude Sonnet subagents** performing web searches. A full run (prepare + 5 search iterations) can consume significant API credits. 20 iterations will consume considerably more. Monitor your Anthropic dashboard usage.

Rough estimate: a 5-iteration run costs approximately $5-15 in API usage depending on the complexity of the role and the number of candidates found. Scale accordingly.

### Ralph runs unsupervised

`loop.bat` passes `--dangerously-skip-permissions` to Claude Code, which means Ralph can search the web, read files, and write files without asking you for confirmation at each step. This is by design — Ralph needs autonomy to loop. But understand what it means: once you hit Enter, Ralph is driving.

## What's Next

Ralph currently finds people and writes the message. The next logical step is **Send Ralph** — hooking the outreach messages into LinkedIn InMail, email, or carrier pigeon APIs to actually deliver them. The structured CSV makes this trivial. The ethical implications of a Simpsons character autonomously cold-messaging senior engineers about their career are left as an exercise for the reader.

## Credit

Built on the [Ralph Wiggum technique](https://ghuntley.com/ralph/) — the art of letting an LLM loop autonomously through tasks, stumbling forward through iteration until the job is done. Originally conceived by [@GeoffreyHuntley](https://github.com/ghuntley) for [software engineering](https://github.com/ghuntley/how-to-ralph-wiggum), adapted here for recruiting, because if Ralph can ship a $50,000 contract for $297, he can probably find you a Principal Engineer.

## License

MIT-0
