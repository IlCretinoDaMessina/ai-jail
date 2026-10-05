@echo off
setlocal
rem Run from the modern-install directory after saving the package files.
rem This runs offline fixtures only. It does not invoke the Phase 020 runner.
set "AIJ_TEST_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
for %%T in (010-warning-completion.tests.ps1 010-engine-bootstrap.tests.ps1 010-preflight.tests.ps1 010-bound-execution.tests.ps1 000-deliverable3.tests.ps1) do (
    echo Running %%T
    "%AIJ_TEST_PS%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\%%T"
    if errorlevel 1 goto failed
)
echo WARNING_POLICY_REGRESSIONS_OK
exit /b 0
:failed
echo WARNING_POLICY_REGRESSIONS_FAILED
exit /b 1
