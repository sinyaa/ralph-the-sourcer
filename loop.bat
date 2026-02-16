@echo off
setlocal enabledelayedexpansion

:: Usage: loop.bat [search_iterations] [target_candidates]
:: Examples:
::   loop.bat              # Full run: prepare (2 passes) + search (5 iterations)
::   loop.bat 10           # Full run: prepare (2 passes) + search (10 iterations)
::   loop.bat 0 100        # Unlimited iterations, stop when 100 candidates found
::   loop.bat 20 50        # Up to 20 iterations, or stop early at 50 candidates

set "SEARCH_ITERATIONS=5"
set "TARGET_CANDIDATES=0"

:: Parse optional arguments
set "ARG1=%~1"
set "ARG2=%~2"
if defined ARG1 (
    set /a "SEARCH_ITERATIONS=%ARG1%" 2>nul
)
if defined ARG2 (
    set /a "TARGET_CANDIDATES=%ARG2%" 2>nul
)

echo ========================================
echo  Candidate Search Agent
echo  Step 1: Prepare pass 1 (analyze + questions)
echo  Step 2: Prepare pass 2 (answer + finalize plan)
echo  Step 3: Search (%SEARCH_ITERATIONS% iterations)
if %TARGET_CANDIDATES% gtr 0 (
echo  Target: %TARGET_CANDIDATES% candidates
)
echo ========================================

:: Verify required files exist
if not exist "PROMPT_PREPARE.md" (
    echo Error: PROMPT_PREPARE.md not found
    exit /b 1
)

if not exist "PROMPT_SOURCE.md" (
    echo Error: PROMPT_SOURCE.md not found
    exit /b 1
)

if not exist "Job_requirements.md" (
    echo Error: Job_requirements.md not found — define the role first
    exit /b 1
)

if not exist "AGENTS.md" (
    echo Error: AGENTS.md not found — operational guide required
    exit /b 1
)

:: ============================================================
:: STEP 1: Prepare Pass 1 — analyze role, generate questions, self-answer
:: ============================================================
echo.
echo ============ PREPARE PASS 1: Analyze Role + Generate Questions ============
echo.

type "PROMPT_PREPARE.md" | claude -p --verbose --dangerously-skip-permissions --model opus --output-format=stream-json ^

if exist "CANDIDATE_SEARCH_PLAN.md" (
    for %%F in (CANDIDATE_SEARCH_PLAN.md) do echo  CANDIDATE_SEARCH_PLAN.md updated: %%~tF
)

:: ============================================================
:: STEP 2: Prepare Pass 2 — read answers, build scoring rubric + search vectors
:: ============================================================
echo.
echo ============ PREPARE PASS 2: Refine Plan from Answers ============
echo.

type "PROMPT_PREPARE.md" | claude -p --verbose ^
    --dangerously-skip-permissions ^
    --output-format=stream-json ^
    --model opus

if exist "CANDIDATE_SEARCH_PLAN.md" (
    for %%F in (CANDIDATE_SEARCH_PLAN.md) do echo  CANDIDATE_SEARCH_PLAN.md updated: %%~tF
)

:: ============================================================
:: STEP 3: Search loop — find and evaluate candidates
:: ============================================================
set "ITERATION=0"

:search_loop
if %SEARCH_ITERATIONS% gtr 0 (
    if %ITERATION% geq %SEARCH_ITERATIONS% (
        echo.
        echo ========================================
        echo  Done. Completed full pipeline:
        echo    - 2 prepare passes
        echo    - %SEARCH_ITERATIONS% search iterations
        echo  Review candidates.csv for results.
        echo  Review CANDIDATE_SEARCH_PLAN.md for strategy.
        echo ========================================
        goto :end
    )
)

set /a "DISPLAY_ITER=%ITERATION%+1"
echo.
echo ============ SEARCH ITERATION %DISPLAY_ITER% of %SEARCH_ITERATIONS% ============
echo.

type "PROMPT_SOURCE.md" | claude -p --verbose ^
    --dangerously-skip-permissions ^
    --output-format=stream-json ^
    --model opus
    

set /a "ITERATION+=1"

:: Confirm file writes after each iteration
if exist "candidates.csv" (
    set "CANDIDATE_COUNT=0"
    for /f %%A in ('type "candidates.csv" ^| find /c /v ""') do set /a "CANDIDATE_COUNT=%%A-1"
    for %%F in (candidates.csv) do echo  candidates.csv: !CANDIDATE_COUNT! candidates [%%~tF]
) else (
    echo  WARNING: candidates.csv not found after iteration
)
if exist "CANDIDATE_SEARCH_PLAN.md" (
    for %%F in (CANDIDATE_SEARCH_PLAN.md) do echo  CANDIDATE_SEARCH_PLAN.md updated: %%~tF
)

:: Check if target candidate count has been reached
if %TARGET_CANDIDATES% gtr 0 (
    if exist "candidates.csv" (
        echo  Progress: !CANDIDATE_COUNT! / %TARGET_CANDIDATES% candidates
        if !CANDIDATE_COUNT! geq %TARGET_CANDIDATES% (
            echo.
            echo ========================================
            echo  Target reached! !CANDIDATE_COUNT! candidates found.
            echo  Completed:
            echo    - 2 prepare passes
            echo    - %ITERATION% search iterations
            echo  Review candidates.csv for results.
            echo  Review CANDIDATE_SEARCH_PLAN.md for strategy.
            echo ========================================
            goto :end
        )
    )
)

goto :search_loop

:end
endlocal
