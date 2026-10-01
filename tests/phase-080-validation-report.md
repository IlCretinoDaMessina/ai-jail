# Phase 080 Preparation and Validation Report

Date: 2026-10-01

## Overall Status

**INCOMPLETE**

The current three wrappers pass the tested sandbox security controls. Phase 080 itself is not complete because `080.bat` intentionally has not been written, and script-level acceptance criteria cannot be tested until it exists.

The preparation is ready to move into implementation, subject to these requirements:

1. Generate allowlists exclusively from `config.env`.
2. Explicitly reject `*`; `ai-jail 2.2.0` accepts it.
3. Treat an empty allowlist as no network.
4. Preserve existing secret files and their secure permissions on reruns.
5. Fail closed on invalid configuration or sandbox startup failure.
6. After writing `080.bat`, test reruns and partial-state recovery for idempotence.

No Phase 000-070 script was rerun. OpenCode and ComfyUI were not installed. Phase 090 and Phase 900 were not started. No global WSL settings or other distributions were changed.

## Test Summary

| Area | Result | Evidence |
| --- | --- | --- |
| Wrapper configuration and syntax | PASS | All three scripts are valid ASCII Bash scripts and match the expected paths, maps, env files, and allowlists. |
| Wrapper executable permissions | PASS | All wrappers are `0700`, `aijail:aijail`. |
| Working directories | PASS | Each wrapper starts in its own project. |
| Environment isolation | PASS | Host-only variables are hidden; only the selected dummy env variable was injected before cleanup. |
| Secret-file hiding | PASS | `.secrets` is not visible in any jail. |
| Own-project writes | PASS | Each wrapper created a host-visible marker in its own project. |
| Cross-project writes | PASS | All six directions failed, and host checks confirmed no denied marker was created. |
| Cross-project reads | PASS | All six peer-project `.git/HEAD` probes were hidden. |
| Private-home behavior | PASS | Writes under jailed `/home/aijail` succeeded but did not modify the real home. |
| System writes | PASS | Writes under `/etc` failed with read-only filesystem errors. |
| Scratch networking | PASS | DNS, direct public IP, and LAN TCP attempts failed. |
| OpenCode allowlist | PASS | npm registry, GitHub, and GitHub objects were reachable; Hugging Face was denied. |
| ComfyUI allowlist | PASS | npm registry, GitHub, and Hugging Face were reachable; GitHub objects and `example.com` were denied. |
| Direct-IP bypass | PASS | Proxy and `--noproxy` probes to `1.1.1.1` failed. |
| LAN bypass | PASS | A reachable WSL DNS endpoint at `10.255.255.254:53` was unreachable from each tested network namespace. |
| Argument forwarding | PASS | Option C supports interactive Bash, `-c COMMAND [ARG...]`, and direct `-- COMMAND [ARG...]`. |
| Failure propagation | PASS | Bash exit `37` and direct-command exit `42` propagated unchanged for all wrappers. |
| No-argument shell | PASS | Each wrapper accepted commands on stdin and exited zero at EOF. |
| Direct command invocation | PASS | `WRAPPER -- /bin/true` exited `0`; direct arguments with spaces were preserved. |
| Malformed invocation handling | PASS | Missing `-c` command, empty `--`, unknown options, and bare commands fail with usage exit `64`. |
| Config persistence | PASS | `--no-save-config` prevents project `.ai-jail` generation across all tested forms. |
| Git state | PASS after cleanup | All three repositories have an initial commit and empty `git status --porcelain`. |
| Ownership/world-writable audit | PASS | No non-`aijail` or world-writable entries were found in projects, bin, or secrets. |
| Dummy env cleanup | PASS | Both env files are empty, `0600`, and `aijail:aijail`. |
| Temporary artifact cleanup | PASS | Test markers and generated `.ai-jail` files were removed. |

## Chronological Command Evidence

PowerShell displayed `$LASTEXITCODE` after commands. For negative tests, the operation's nonzero status was captured inside Bash and then asserted, so `VALIDATION_EXIT=0` means the expected denial occurred.

### 1. Required first inspection

```powershell
wsl -d ai-jail -e cat /home/aijail/bin/jail-comfyui
```

Output:

```text
#!/bin/bash
set -e
cd /home/aijail/projects/comfyui
exec /home/aijail/.cargo/bin/ai-jail --clean --private-home --hide-dotdir .secrets --rw-map /home/aijail/projects/comfyui --allow-host registry.npmjs.org --allow-host github.com --allow-host huggingface.co --env-from-file /home/aijail/.secrets/comfyui.env --terminal-passthrough --exec -- bash "$@"
```

Exit: `0`.

An initial quoted `sh -c` stat probe was malformed by Windows/native argument parsing and returned `stat: missing operand`. It was replaced with a direct `stat` invocation:

```powershell
wsl -d ai-jail -e stat -c "%A %a %U:%G %n" /home/aijail/bin/jail-comfyui
```

```text
-rwx------ 700 aijail:aijail /home/aijail/bin/jail-comfyui
EXIT=0
```

### 2. Static inspection

Commands:

```powershell
wsl -d ai-jail -e cat /home/aijail/bin/jail-shell
wsl -d ai-jail -e cat /home/aijail/bin/jail-opencode
wsl -d ai-jail -e stat -c "%A %a %U:%G %n" /home/aijail/bin /home/aijail/bin/jail-shell /home/aijail/bin/jail-opencode /home/aijail/bin/jail-comfyui /home/aijail/projects /home/aijail/projects/scratch /home/aijail/projects/opencode-work /home/aijail/projects/comfyui /home/aijail/.secrets /home/aijail/.secrets/opencode.env /home/aijail/.secrets/comfyui.env
wsl -d ai-jail -e /home/aijail/.cargo/bin/ai-jail --version
wsl -d ai-jail -e /home/aijail/.cargo/bin/ai-jail --help
```

Relevant output:

```text
All wrapper, project, bin, and secret objects: aijail:aijail
wrappers: 700
projects and bin: 755
.secrets: 700
env files: 600
ai-jail 2.2.0
```

The help output confirmed support for `--rw-map`, `--hide-dotdir`, `--private-home`, `--env-from-file`, `--no-network`, `--allow-host`, `--terminal-passthrough`, `--exec`, `--clean`, and `--no-save-config`. All exits were `0`.

### 3. ComfyUI working directory, environment, and hidden secrets

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'printf "PWD=%s\nCOMFY_ONLY=%s\nOPEN_ONLY=%s\nHOME=%s\n" "$PWD" "${COMFY_ONLY-unset}" "${OPEN_ONLY-unset}" "$HOME"; if [ -e /home/aijail/.secrets ] || [ -e "$HOME/.secrets" ]; then echo SECRETS_VISIBLE; exit 41; fi; echo SECRETS_HIDDEN'
```

Windows argument handling stripped the visual `\n` escapes, but the values and assertions were intact:

```text
PWD=/home/aijail/projects/comfyuinCOMFY_ONLY=testnOPEN_ONLY=unsetnHOME=/home/aijailnSECRETS_HIDDEN
EXIT=0
```

Result: correct directory, only `COMFY_ONLY` injected, `.secrets` hidden.

### 4. ComfyUI write isolation

A pre-test sweep found an unexpected empty test artifact:

```powershell
wsl -d ai-jail -e find /home/aijail/projects -maxdepth 2 -type f -name '.phase080-*' -print
wsl -d ai-jail -e stat -c "%A %a %U:%G %s %y %n" /home/aijail/projects/comfyui/.phase080-comfy-own-test
wsl -d ai-jail -e cat /home/aijail/projects/comfyui/.phase080-comfy-own-test
```

```text
/home/aijail/projects/comfyui/.phase080-comfy-own-test
-rw-r--r-- 644 aijail:aijail 0 ... /home/aijail/projects/comfyui/.phase080-comfy-own-test
STAT_EXIT=0
CAT_EXIT=0
```

It was an empty, clearly named test file and was removed:

```powershell
wsl -d ai-jail -e rm /home/aijail/projects/comfyui/.phase080-comfy-own-test
```

Exit: `0`.

Write test:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'touch /home/aijail/projects/comfyui/.phase080-comfy-own-001; own=$?; touch /home/aijail/projects/opencode-work/.phase080-comfy-to-open-001 2>/dev/null; open=$?; touch /home/aijail/projects/scratch/.phase080-comfy-to-scratch-001 2>/dev/null; scratch=$?; echo OWN_RC=$own; echo OPEN_RC=$open; echo SCRATCH_RC=$scratch; test "$own" -eq 0; test "$open" -ne 0; test "$scratch" -ne 0'
```

```text
OWN_RC=0
OPEN_RC=1
SCRATCH_RC=1
EXIT=0
```

Host verification and cleanup:

```powershell
wsl -d ai-jail -e sh -c 'test -f /home/aijail/projects/comfyui/.phase080-comfy-own-001 && test ! -e /home/aijail/projects/opencode-work/.phase080-comfy-to-open-001 && test ! -e /home/aijail/projects/scratch/.phase080-comfy-to-scratch-001'
wsl -d ai-jail -e rm /home/aijail/projects/comfyui/.phase080-comfy-own-001
```

Both exits: `0`.

### 5. ComfyUI allowed network destinations

`command -v curl` returned `/usr/bin/curl`, exit `0`.

Commands, run separately:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -sS -o /dev/null -w "HTTP=%{http_code}" --connect-timeout 10 --max-time 20 https://registry.npmjs.org/'
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -sS -o /dev/null -w "HTTP=%{http_code}" --connect-timeout 10 --max-time 20 https://github.com/'
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -sS -o /dev/null -w "HTTP=%{http_code}" --connect-timeout 10 --max-time 20 https://huggingface.co/'
```

Each returned `HTTP=200`, exit `0`.

### 6. ComfyUI denied network destinations

Commands, run separately with the curl status asserted nonzero:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -sS -o /dev/null --connect-timeout 5 --max-time 10 https://example.com/; rc=$?; echo CURL_RC=$rc; test "$rc" -ne 0'
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -sS -o /dev/null --connect-timeout 5 --max-time 10 https://objects.githubusercontent.com/; rc=$?; echo CURL_RC=$rc; test "$rc" -ne 0'
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl -k -sS -o /dev/null --connect-timeout 5 --max-time 10 https://1.1.1.1/; rc=$?; echo CURL_RC=$rc; test "$rc" -ne 0'
```

Each produced:

```text
curl: (56) CONNECT tunnel failed, response 403
CURL_RC=56
VALIDATION_EXIT=0
```

### 7. Routing, direct-IP, and LAN bypass

Outside the jail:

```powershell
wsl -d ai-jail -e sh -c 'echo ROUTE; ip route; echo RESOLV; cat /etc/resolv.conf'
```

```text
default via 172.24.224.1 dev eth0
172.24.224.0/20 dev eth0 ... src 172.24.231.16
nameserver 10.255.255.254
EXIT=0
```

Inside ComfyUI, `ip route` failed with `Cannot open netlink socket: Operation not permitted`; the final `cat` made the exploratory command exit `0`. This was not used alone as a passing network test.

Direct-IP bypass with proxy disabled:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'curl --noproxy "*" -k -sS -o /dev/null --connect-timeout 5 --max-time 10 https://1.1.1.1/; rc=$?; echo DIRECT_CURL_RC=$rc; test "$rc" -ne 0'
```

```text
curl: (7) Failed to connect to 1.1.1.1 port 443 ...
DIRECT_CURL_RC=7
VALIDATION_EXIT=0
```

LAN control proved the target was reachable outside the jail:

```powershell
wsl -d ai-jail -e bash -c 'echo probe >/dev/tcp/10.255.255.254/53'
```

`CONTROL_EXIT=0`.

The same endpoint inside ComfyUI:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'echo probe >/dev/tcp/10.255.255.254/53 2>/dev/null; rc=$?; echo LAN_TCP_RC=$rc; test "$rc" -ne 0'
```

```text
Network is unreachable
LAN_TCP_RC=1
VALIDATION_EXIT=0
```

### 8. Private-home and system write behavior

ComfyUI command:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-comfyui -c 'echo disposable > /home/aijail/.phase080-comfy-private-001; home_rc=$?; echo denied > /etc/.phase080-comfy-etc-001 2>/dev/null; etc_rc=$?; echo HOME_WRITE_RC=$home_rc; echo ETC_WRITE_RC=$etc_rc; test "$home_rc" -eq 0; test "$etc_rc" -ne 0'
```

```text
HOME_WRITE_RC=0
ETC_WRITE_RC=1
/etc/...: Read-only file system
JAIL_VALIDATION_EXIT=0
HOST_UNCHANGED_EXIT=0
```

Equivalent commands were run through `jail-shell` and `jail-opencode`. Both returned `HOME_WRITE_RC=0`, `ETC_WRITE_RC=1`, `JAIL_VALIDATION_EXIT=0`, and `HOST_UNCHANGED_EXIT=0`.

### 9. Scratch and OpenCode environment and write isolation

Scratch:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -c 'echo PWD=$PWD; echo OPEN_ONLY=${OPEN_ONLY-unset}; echo COMFY_ONLY=${COMFY_ONLY-unset}; if [ -e /home/aijail/.secrets ]; then echo SECRETS_VISIBLE; secrets=1; else echo SECRETS_HIDDEN; secrets=0; fi; touch /home/aijail/projects/scratch/.phase080-shell-own-001; own=$?; touch /home/aijail/projects/opencode-work/.phase080-shell-to-open-001 2>/dev/null; open=$?; touch /home/aijail/projects/comfyui/.phase080-shell-to-comfy-001 2>/dev/null; comfy=$?; echo OWN_RC=$own; echo OPEN_RC=$open; echo COMFY_RC=$comfy; test "$PWD" = /home/aijail/projects/scratch; test "${OPEN_ONLY-unset}" = unset; test "${COMFY_ONLY-unset}" = unset; test "$secrets" -eq 0; test "$own" -eq 0; test "$open" -ne 0; test "$comfy" -ne 0'
```

```text
PWD=/home/aijail/projects/scratch
OPEN_ONLY=unset
COMFY_ONLY=unset
SECRETS_HIDDEN
OWN_RC=0
OPEN_RC=1
COMFY_RC=1
JAIL_VALIDATION_EXIT=0
HOST_VERIFY_EXIT=0
CLEANUP_EXIT=0
```

OpenCode used the equivalent command and returned:

```text
PWD=/home/aijail/projects/opencode-work
OPEN_ONLY=test
COMFY_ONLY=unset
SECRETS_HIDDEN
OWN_RC=0
SCRATCH_RC=1
COMFY_RC=1
JAIL_VALIDATION_EXIT=0
HOST_VERIFY_EXIT=0
CLEANUP_EXIT=0
```

### 10. Scratch and OpenCode networking

Scratch tested a hostname, direct public IP, and reachable LAN endpoint:

```text
curl: (6) Could not resolve host: registry.npmjs.org
curl: (7) Failed to connect to 1.1.1.1 port 443
Network is unreachable for 10.255.255.254:53
HOST_RC=6
DIRECT_IP_RC=7
LAN_RC=1
VALIDATION_EXIT=0
```

OpenCode allowed-host commands returned:

```text
registry.npmjs.org: HTTP=200, EXIT=0
github.com: HTTP=200, EXIT=0
objects.githubusercontent.com: HTTP=404, EXIT=0
```

The `404` still proves the TLS/HTTP connection to the allowed host succeeded.

OpenCode denial command tested Hugging Face, `--noproxy` public IP, and LAN TCP:

```text
HUGGINGFACE_RC=56
DIRECT_IP_RC=7
LAN_RC=1
VALIDATION_EXIT=0
```

### 11. Argument forwarding, Bash behavior, and exit propagation

The first positional-argument test used nested quoted `[[ ... ]]` syntax. Windows/native quoting corrupted the test script before it reached Bash, so all three attempts exited `2` with `unexpected EOF while looking for ]]`. This was a test-harness failure, not a sandbox result.

The corrected command avoided nested quote dependence and was run through all three wrappers:

```powershell
wsl -d ai-jail -e WRAPPER -c 'echo ARG1_UNDERSCORE=${1// /_}; echo ARG1_LENGTH=${#1}; echo ARG2_LENGTH=${#2}; test ${#1} -eq 9; test ${#2} -eq 13' phase080 'two words' 'literal*value'
```

Each returned:

```text
ARG1_UNDERSCORE=two_words
ARG1_LENGTH=9
ARG2_LENGTH=13
EXIT=0
```

Failure propagation was tested on all wrappers:

```powershell
wsl -d ai-jail -e WRAPPER -c 'exit 37'
```

Each returned `EXIT=37`.

A no-argument stdin test initially included `exit 23`. PowerShell supplied CRLF, making Bash parse `23\r`; that exploratory run exited `2` with `numeric argument required`. The corrected EOF-based no-argument test was run on all wrappers:

```powershell
@('echo NOARG_PWD=$PWD') | wsl -d ai-jail -e WRAPPER
```

Each printed its correct project directory and exited `0`.

Direct command behavior:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell /bin/true
```

```text
/bin/true: /bin/true: cannot execute binary file
EXIT=126
```

Historical conclusion before the Option C decision: `bash "$@"` correctly forwarded Bash arguments but did not provide a transparent command interface. The Option C follow-up below supersedes this behavior with explicit `-- COMMAND [ARG...]` execution.

### 12. Host environment isolation

Each wrapper was launched after setting `PHASE080_HOST_ONLY=host-value` in the PowerShell process. Each jail ran:

```bash
if env | grep -q ^PHASE080_HOST_ONLY=; then echo LEAKED; exit 1; else echo HOST_ENV_HIDDEN; fi
```

Each returned:

```text
HOST_ENV_HIDDEN
EXIT=0
```

### 13. Git, ownership, permissions, and temporary files

Initial Git audit:

```powershell
wsl -d ai-jail -e git -C PROJECT status --short --branch
wsl -d ai-jail -e git -C PROJECT log -1 --format=%H%x20%an%x20%s
```

All projects had the same valid initial commit and an untracked `.ai-jail`:

```text
## master
?? .ai-jail
b128d2a03c0dede852982196c0819cb810d45e24 ai-jail initial
```

Inspection showed that wrapper execution auto-saved the most recent command and wrapper settings to mode-`0600` project `.ai-jail` files. No env-file values were stored. These files were removed after tests.

Audits:

```powershell
wsl -d ai-jail -e find /home/aijail/projects -maxdepth 3 -printf "%M %m %u:%g %y %p\n"
wsl -d ai-jail -e find /home/aijail/bin /home/aijail/.secrets -maxdepth 2 -printf "%M %m %u:%g %y %s %p\n"
wsl -d ai-jail -e find /home/aijail/projects /home/aijail/bin /home/aijail/.secrets -xdev '(' -not -user aijail -o -not -group aijail -o -perm -0002 ')' -printf "%M %u:%g %p\n"
```

All exited `0`. The violation search produced no output.

Syntax and file format:

```powershell
wsl -d ai-jail -e bash -n /home/aijail/bin/jail-shell /home/aijail/bin/jail-opencode /home/aijail/bin/jail-comfyui
wsl -d ai-jail -e file /home/aijail/bin/jail-shell /home/aijail/bin/jail-opencode /home/aijail/bin/jail-comfyui
```

`bash -n` exited `0`; all were reported as ASCII Bourne-Again shell scripts. A search for `*phase080*`, `*test*`, and `*.tmp` project files produced no output, exit `0`.

### 14. Wildcard behavior

Dry-run only; unrestricted network was not started:

```powershell
wsl -d ai-jail --cd /home/aijail/projects/scratch -e /home/aijail/.cargo/bin/ai-jail --clean --no-save-config --allow-host "*" --dry-run --exec -- true
```

The generated command contained:

```text
--allow-host '*'
```

Exit: `0`.

Conclusion: `ai-jail 2.2.0` does not enforce the project's `*` prohibition. `080.bat` must reject it before invoking `ai-jail` or writing wrappers.

### 15. Dummy environment cleanup

An attempted nested `sh -c` precheck was malformed by Windows/native quoting and exited `2`. The prior wrapper output and file sizes had already established the known dummy values.

Cleanup:

```powershell
wsl -d ai-jail -e truncate -s 0 /home/aijail/.secrets/opencode.env /home/aijail/.secrets/comfyui.env
wsl -d ai-jail -e chmod 600 /home/aijail/.secrets/opencode.env /home/aijail/.secrets/comfyui.env
```

Both exited `0`.

Post-cleanup wrapper checks:

```text
OPEN_ONLY=unset
COMFY_ONLY=unset
EXIT=0
```

Both OpenCode and ComfyUI also asserted that `/home/aijail/.secrets` remained hidden.

### 16. Cross-project read isolation

Each wrapper tested both peer projects using `.git/HEAD` as a known existing file:

```text
jail-shell: opencode-work=HIDDEN, comfyui=HIDDEN, EXIT=0
jail-opencode: scratch=HIDDEN, comfyui=HIDDEN, EXIT=0
jail-comfyui: scratch=HIDDEN, opencode-work=HIDDEN, EXIT=0
```

### 17. Final cleanup and state

Generated `.ai-jail` files were removed. A combined quoted final-state command was malformed and exited `2`; it was replaced by direct independent checks.

Final commands:

```powershell
wsl -d ai-jail -e git -C /home/aijail/projects/scratch status --porcelain
wsl -d ai-jail -e git -C /home/aijail/projects/opencode-work status --porcelain
wsl -d ai-jail -e git -C /home/aijail/projects/comfyui status --porcelain
wsl -d ai-jail -e test ! -s /home/aijail/.secrets/opencode.env
wsl -d ai-jail -e test ! -s /home/aijail/.secrets/comfyui.env
wsl -d ai-jail -e find /home/aijail/projects -maxdepth 2 -type f -not -path '*/.git/*' -print
```

All exited `0`; all expected-empty outputs were empty.

## Option C Follow-up Validation

Decision: all wrappers support both a Bash interface and an explicit direct-command interface.

Accepted forms:

```text
WRAPPER
WRAPPER -c COMMAND [ARG...]
WRAPPER -- COMMAND [ARG...]
```

Any other first argument is rejected before `ai-jail` starts. Missing `-c` commands and empty `--` command lists are also rejected. Usage errors exit `64`.

Every wrapper now passes `--no-save-config` to `ai-jail`. Project `.ai-jail` files remained absent after interactive, Bash, direct-command, failure, filesystem, and network tests.

### Deployment Evidence

`jail-shell` was changed and fully tested first. OpenCode and ComfyUI were changed only after shell validation passed.

The first shell payload transfer used a PowerShell text pipeline. Base64 decoding rejected the altered input and exited `1`; atomic deployment left the original wrapper untouched. The partial `.jail-shell.new` was removed. The corrected transfer passed Base64 as one argument, verified the decoded SHA-256 before deployment, ran `bash -n`, set mode `0700`, and atomically renamed the file.

Final deployed hashes:

```text
c3d2d32428f6f2e49f471e41e8e2d43eef38075ab47c0652fec85234d4e2455e  /home/aijail/bin/jail-shell
813e75722d44d5f545ab60d59a582264fc15324f29fa5c9a3ff9a98d3c919102  /home/aijail/bin/jail-opencode
15687c83bce118d8235470323bb45f27637797a8bb9daa947038aa9883d7539a  /home/aijail/bin/jail-comfyui
EXIT=0
```

### Shell Interface Tests

Interactive Bash:

```powershell
@('echo INTERACTIVE_PWD=$PWD') | wsl -d ai-jail -e /home/aijail/bin/jail-shell
```

```text
INTERACTIVE_PWD=/home/aijail/projects/scratch
WRAPPER_EXIT=0
NO_CONFIG_EXIT=0
```

Bash command:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -c 'echo hello'
```

```text
hello
WRAPPER_EXIT=0
NO_CONFIG_EXIT=0
```

Direct command:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -- /bin/true
```

```text
WRAPPER_EXIT=0
NO_CONFIG_EXIT=0
```

Malformed invocations:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -c
wsl -d ai-jail -e /home/aijail/bin/jail-shell --
wsl -d ai-jail -e /home/aijail/bin/jail-shell /bin/true
wsl -d ai-jail -e /home/aijail/bin/jail-shell -x
```

Each printed:

```text
Usage: jail-shell [-c COMMAND [ARG...]] | [-- COMMAND [ARG...]]
WRAPPER_EXIT=64
NO_CONFIG_EXIT=0
```

Argument preservation:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -c 'echo BASH_ARG_UNDERSCORE=${1// /_}; echo BASH_ARG_LENGTH=${#1}; test ${#1} -eq 9' phase080 'two words'
wsl -d ai-jail -e /home/aijail/bin/jail-shell -- /bin/sh -c 'echo DIRECT_ARG_LENGTH=${#1}; test ${#1} -eq 9' phase080 'two words'
```

```text
BASH_ARG_UNDERSCORE=two_words
BASH_ARG_LENGTH=9
BASH exit=0
DIRECT_ARG_LENGTH=9
direct exit=0
```

Failure propagation:

```powershell
wsl -d ai-jail -e /home/aijail/bin/jail-shell -c 'exit 37'
wsl -d ai-jail -e /home/aijail/bin/jail-shell -- /bin/sh -c 'exit 42'
wsl -d ai-jail -e /home/aijail/bin/jail-shell -- /phase080-command-does-not-exist
```

```text
BASH_EXIT=37
DIRECT_EXIT=42
Failed to exec /phase080-command-does-not-exist: No such file or directory
WRAPPER_EXIT=1
NO_CONFIG_EXIT=0
```

### Shell Security Regression

The shell regression rechecked its working directory, hidden `.secrets`, own-project write, both peer read and write denials, host-side absence of denied files, and marker cleanup:

```text
PWD=/home/aijail/projects/scratch
OWN_RC=0
OPEN_WRITE_RC=1
COMFY_WRITE_RC=1
OPEN_READ_RC=1
COMFY_READ_RC=1
JAIL_VALIDATION_EXIT=0
OWN_HOST_EXIT=0
OPEN_HOST_UNCHANGED_EXIT=0
COMFY_HOST_UNCHANGED_EXIT=0
CLEANUP_EXIT=0
```

No-network regression:

```text
registry.npmjs.org: curl exit 6, could not resolve host
1.1.1.1 with --noproxy: curl exit 7
10.255.255.254:53: network unreachable, exit 1
VALIDATION_EXIT=0
NO_CONFIG_EXIT=0
```

Host environment and filesystem regression:

```text
HOST_ENV_PROBE_RC=1
HOME_WRITE_RC=0
ETC_WRITE_RC=1, read-only filesystem
JAIL_VALIDATION_EXIT=0
HOST_HOME_UNCHANGED_EXIT=0
HOST_ETC_UNCHANGED_EXIT=0
```

### OpenCode and ComfyUI Interface Tests

The accepted-form tests were repeated for both networked wrappers:

```text
jail-opencode interactive PWD=/home/aijail/projects/opencode-work, exit 0
jail-comfyui interactive PWD=/home/aijail/projects/comfyui, exit 0
both `-c 'echo hello'`: hello, exit 0
both `-- /bin/true`: exit 0
all corresponding NO_CONFIG_EXIT values: 0
```

For each wrapper, missing `-c`, empty `--`, and bare `/bin/true` printed wrapper-specific usage and exited `64`. No `.ai-jail` file was created.

Both wrappers preserved a nine-character `two words` argument in Bash and direct modes. Both propagated Bash exit `37` and direct exit `42` unchanged.

### OpenCode and ComfyUI Security Regression

OpenCode:

```text
PWD=/home/aijail/projects/opencode-work
OPEN_ONLY=unset
OWN_RC=0
SCRATCH_WRITE_RC=1
COMFY_WRITE_RC=1
SCRATCH_READ_RC=1
COMFY_READ_RC=1
JAIL_VALIDATION_EXIT=0
all host verification and cleanup exits=0
```

ComfyUI:

```text
PWD=/home/aijail/projects/comfyui
COMFY_ONLY=unset
OWN_RC=0
SCRATCH_WRITE_RC=1
OPEN_WRITE_RC=1
SCRATCH_READ_RC=1
OPEN_READ_RC=1
JAIL_VALIDATION_EXIT=0
all host verification and cleanup exits=0
```

Both wrappers hid `.secrets`. Their env variables were unset because the final env files are intentionally empty.

Allowed destinations were tested through the direct-command interface:

```text
OpenCode registry.npmjs.org: HTTP 200, exit 0
OpenCode github.com: HTTP 200, exit 0
OpenCode objects.githubusercontent.com: HTTP 404, exit 0
ComfyUI registry.npmjs.org: HTTP 200, exit 0
ComfyUI github.com: HTTP 200, exit 0
ComfyUI huggingface.co: HTTP 200, exit 0
```

Denied destinations and bypasses:

```text
OpenCode huggingface.co: proxy 403, curl exit 56
ComfyUI objects.githubusercontent.com: proxy 403, curl exit 56
Both direct 1.1.1.1 probes with --noproxy: curl exit 7
Both LAN 10.255.255.254:53 probes: network unreachable, operation exit 1, validation exit 0
```

Both wrappers repeated the host-only environment, disposable private-home, read-only `/etc`, and real-host unchanged checks with the same passing results as `jail-shell`.

### Option C Final Audit

```text
bash -n all wrappers: exit 0
all wrappers: 0700 aijail:aijail
find project .ai-jail files: no output, exit 0
find wrapper *.new files: no output, exit 0
.secrets: 0700 aijail:aijail
both env files: 0600 aijail:aijail, size 0
all three Git repositories: ## master with no changes
ownership/world-writable violation search: no output, exit 0
project non-Git temporary-file search: no output, exit 0
```

## Exact Final Wrapper Contents

### `/home/aijail/bin/jail-shell`

```bash
#!/bin/bash
set -e

usage() {
    echo "Usage: jail-shell [-c COMMAND [ARG...]] | [-- COMMAND [ARG...]]" >&2
    exit 64
}

cd /home/aijail/projects/scratch

case "$#:$1" in
    0:)
        set -- bash
        ;;
    *:-c)
        [ "$#" -ge 2 ] || usage
        set -- bash "$@"
        ;;
    *:--)
        shift
        [ "$#" -ge 1 ] || usage
        ;;
    *)
        usage
        ;;
esac

exec /home/aijail/.cargo/bin/ai-jail --clean --no-save-config --private-home --hide-dotdir .secrets --rw-map /home/aijail/projects/scratch --no-network --terminal-passthrough --exec -- "$@"
```

### `/home/aijail/bin/jail-opencode`

```bash
#!/bin/bash
set -e

usage() {
    echo "Usage: jail-opencode [-c COMMAND [ARG...]] | [-- COMMAND [ARG...]]" >&2
    exit 64
}

cd /home/aijail/projects/opencode-work

case "$#:$1" in
    0:)
        set -- bash
        ;;
    *:-c)
        [ "$#" -ge 2 ] || usage
        set -- bash "$@"
        ;;
    *:--)
        shift
        [ "$#" -ge 1 ] || usage
        ;;
    *)
        usage
        ;;
esac

exec /home/aijail/.cargo/bin/ai-jail --clean --no-save-config --private-home --hide-dotdir .secrets --rw-map /home/aijail/projects/opencode-work --allow-host registry.npmjs.org --allow-host github.com --allow-host objects.githubusercontent.com --env-from-file /home/aijail/.secrets/opencode.env --terminal-passthrough --exec -- "$@"
```

### `/home/aijail/bin/jail-comfyui`

```bash
#!/bin/bash
set -e

usage() {
    echo "Usage: jail-comfyui [-c COMMAND [ARG...]] | [-- COMMAND [ARG...]]" >&2
    exit 64
}

cd /home/aijail/projects/comfyui

case "$#:$1" in
    0:)
        set -- bash
        ;;
    *:-c)
        [ "$#" -ge 2 ] || usage
        set -- bash "$@"
        ;;
    *:--)
        shift
        [ "$#" -ge 1 ] || usage
        ;;
    *)
        usage
        ;;
esac

exec /home/aijail/.cargo/bin/ai-jail --clean --no-save-config --private-home --hide-dotdir .secrets --rw-map /home/aijail/projects/comfyui --allow-host registry.npmjs.org --allow-host github.com --allow-host huggingface.co --env-from-file /home/aijail/.secrets/comfyui.env --terminal-passthrough --exec -- "$@"
```

## Final Permissions and State

```text
-rwx------ 700 aijail:aijail 586 /home/aijail/bin/jail-shell
-rwx------ 700 aijail:aijail 738 /home/aijail/bin/jail-opencode
-rwx------ 700 aijail:aijail 709 /home/aijail/bin/jail-comfyui
drwxr-xr-x 755 aijail:aijail /home/aijail/projects/scratch
drwxr-xr-x 755 aijail:aijail /home/aijail/projects/opencode-work
drwxr-xr-x 755 aijail:aijail /home/aijail/projects/comfyui
drwx------ 700 aijail:aijail /home/aijail/.secrets
-rw------- 600 aijail:aijail 0 /home/aijail/.secrets/opencode.env
-rw------- 600 aijail:aijail 0 /home/aijail/.secrets/comfyui.env
```

All three Git worktrees are clean. No non-Git files remain in the project roots. No ownership or world-writable violations were found.

## Differences and Warnings

1. Documentation says allowlists come exclusively from `config.env`. The current manually created wrappers hard-code values that match `config.env`; provenance and update behavior cannot be proven until `080.bat` generates them.
2. Documentation requires `*` rejection, but `ai-jail 2.2.0` accepts `--allow-host "*"`. The batch script must enforce rejection fail-closed.
3. The wrapper interface is now explicitly Option C. No args opens Bash, `-c` selects Bash execution, and `--` selects direct execution. Bare commands without `--` intentionally fail with status `64`.
4. `--no-save-config` resolved the generated project `.ai-jail` issue. No configuration files were generated during the follow-up suite.
5. The existing project plan requires empty allowlists to mean no network. Scratch proves explicit `--no-network`; the future config-to-wrapper empty-list branch remains unimplemented and therefore untested.
6. Existing secret files and permissions must be preserved by the future idempotent installer. The current empty files were not modified during Option C work.
7. External-host checks prove policy at the time of testing but depend on DNS and public service availability. The LAN control reduced ambiguity by proving the selected LAN target was reachable outside the jail.

## Remaining Work for ChatGPT

1. Write `080.bat` using `_common.bat` contracts and LF-safe wrapper generation, but only after review of this report.
2. Generate the tested Option C wrappers, including `--no-save-config`, exactly and fail closed if writing, ownership, permission, syntax, or sandbox checks fail.
3. Parse `ALLOW_HOSTS_OPENCODE` and `ALLOW_HOSTS_COMFYUI` exclusively from `config.env`.
4. Validate each allowlist entry and reject `*`, empty elements, malformed hosts, and unsafe shell/batch characters fail-closed.
5. Emit `--no-network` when an allowlist is empty.
6. Preserve ownership and modes: wrappers `0700`, `.secrets` `0700`, env files `0600`.
7. Preserve existing nonempty secret files and their permissions on rerun; never truncate real credentials.
8. Fail closed on invalid configuration and any `ai-jail` startup failure.
9. Test `080.bat` from clean state, repeated state, invalid configuration, sandbox-startup failure, and safe partial state. Confirm exact exit codes and logs.
10. Rerun the Phase 080 acceptance suite against artifacts generated by the batch script before starting Phase 090.
