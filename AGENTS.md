# AGENTS.md — Candidate Search Loop Operations

This is the operational guide for Ralph. Read this first every iteration.

## How the Search Loop Works

1. Read `AGENTS.md` (this file) — operational rules and validation steps.
2. Read `Job_requirements.md` — scoring rubric source of truth.
3. Read `CANDIDATE_SEARCH_PLAN.md` — scoring rubric, search vectors, ideal candidate profile.
4. Read `candidates.csv` — current candidate pool.
5. Search for new candidates using vectors from `CANDIDATE_SEARCH_PLAN.md`.
6. **Validate** every candidate before writing to candidates.csv (see below).
7. Update `CANDIDATE_SEARCH_PLAN.md` with iteration results.

## Validation — Run After Every Search

Before finalizing candidates.csv each iteration, run this validation pass.
This is the loopback — it catches scoring drift, stale candidates, and bad data.

### Step 1: Re-score all candidates against Job_requirements.md
- Read `candidates.csv` and `Job_requirements.md`
- For each candidate row, use a Sonnet subagent to web-search the candidate's name + company
- Re-evaluate each scoring dimension using the **Scoring Rubric** in CANDIDATE_SEARCH_PLAN.md:
  - **SkillsMatch (25%)**: Count required/preferred skills demonstrably held. No evidence = score 1-3.
  - **ExperienceDepth (25%)**: Verify years and seniority match role demands. Check title history. **For IC roles: if the candidate's last 2-3 years are primarily people management (VP, Director, GM, Head of) rather than hands-on technical work, cap this score at 5 regardless of earlier IC credentials.**
  - **DomainCredibility (20%)**: Verify public artifacts (paper, repo, talk, patent, portfolio). None = score 1-3.
  - **LeadershipSignal (15%)**: Look for team/org-level impact evidence. Scale to role requirements. **For IC roles: score technical leadership (architecture ownership, mentoring, cross-team influence, RFC authorship) — not people-management signals (headcount, budget, org building).**
  - **AvailabilitySignal (15%)**: Check tenure, recent changes, "open to work" signals. **Geographic adjustment (location-specific roles only):** candidates already in the target metro get +1 to +2; same-country candidates score neutral; international candidates needing relocation/visa get -1 to -2. **Skip this adjustment entirely for remote roles with no location preference.**
- Recalculate OverallScore. If changed by more than 0.5, set Status to UPGRADED or DOWNGRADED.

### Step 2: IC/Manager fit check
- Read the **Target Role** section of `CANDIDATE_SEARCH_PLAN.md` to confirm whether this is an IC or Manager role.
- **For IC roles:** Flag any candidate whose current title and daily work is primarily people management (VP, Director, General Manager, Head of Engineering, SVP, CTO of large org). Check what they actually do NOW — not what they did 5 years ago.
- DOWNGRADE flagged candidates. Exception: candidates with clear public signals of wanting to return to IC (recently left management, profile says "open to IC roles", stepped down to return to technical work).
- Add "IC/MANAGER MISMATCH" to Notes for any flagged candidate.

### Step 3: Geographic fit check
- Read the **Target Role** section of `CANDIDATE_SEARCH_PLAN.md` for the location model.
- **If a target location is specified (on-site/hybrid):** Verify each candidate's current location via LinkedIn/web search. Ensure AvailabilitySignal includes the geographic adjustment: in-metro +1 to +2, same-country neutral, international relocation -1 to -2. Add location to Notes if not already recorded.
- **If the role is remote with no location preference:** Skip this step entirely — do not adjust scores based on geography.

### Step 4: Dedup check
- Sort by Name. Flag and merge duplicates (same person, different spellings).

### Step 5: Threshold enforcement
- Iteration 1-3: Remove OverallScore < 5.0
- Iteration 4-5: Remove OverallScore < 6.0
- Iteration 6+: Remove OverallScore < 7.0

### Step 6: Concentration check
- No single company > 20% of pool. Downgrade weakest from over-represented companies.

### Step 7: Outreach message check
- Every NEW or UPGRADED candidate must have an OutreachMessage (non-empty, under 200 words).
- Message must reference something specific to the candidate (not generic).
- KEPT candidates retain their existing message. DOWNGRADED candidates get cleared.

### Step 8: Gap report
- Identify Job_requirements.md skills with zero/few candidates. Write to CANDIDATE_SEARCH_PLAN.md gaps section.

## File Discipline — MANDATORY

The pipeline produces exactly **two output files**. No others may be created.

| File | Who writes it | Purpose |
|------|--------------|---------|
| `CANDIDATE_SEARCH_PLAN.md` | Prepare phase + Search phase | Strategy, rubric, progress tracking, gap analysis, validation results |
| `candidates.csv` | Search phase only | The deliverable. Scored candidates with outreach messages. |

**Rules:**
1. **Do NOT create any other files.** No research files, no reports, no summaries, no outreach text files, no scratch files. Nothing.
2. **Subagents must return their results in their response.** They must NOT write files. Research findings, validation results, and analysis stay in the agent's context and get synthesized into the two output files above.
3. All validation results (dedup, concentration, threshold, gap analysis) go into the `Candidate Pool Gaps` section of `CANDIDATE_SEARCH_PLAN.md` — not into a separate validation report.
4. Outreach messages go in the `OutreachMessage` column of `candidates.csv` — not into a separate text file.
5. If you find yourself about to create a new file, STOP. Put that content into `CANDIDATE_SEARCH_PLAN.md` or `candidates.csv` instead.

**Read-only files (never modify these):**
- `Job_requirements.md` — the single source of truth for the role.
- `AGENTS.md` — this file. Operational rules.
- `PROMPT_PREPARE.md` — prepare phase prompt.
- `PROMPT_SOURCE.md` — search phase prompt.
- `loop.bat` — the loop script.


## Operational Notes

- `Job_requirements.md` is the single source of truth. If the role changes, re-run the full pipeline.
- `candidates.csv` is the deliverable. Sorted by OverallScore desc, no orphan REMOVED rows.
- `CANDIDATE_SEARCH_PLAN.md` tracks strategy and progress. Keep under 150 lines.
- This file (`AGENTS.md`) is operational only. No status updates or progress here.

## Codebase Patterns

- CSV fields with commas must be double-quoted.
- Skills field uses semicolons as separators, not commas.
- LinkedIn field: leave blank if not confirmed via search. Never guess URLs.
- Source field: URL where you found the strongest evidence for the candidate.
- LastUpdated: always YYYY-MM-DD for every row touched.
- OutreachMessage field: double-quoted, under 200 words, personalized to the candidate. Empty for DOWNGRADED/REMOVED.
