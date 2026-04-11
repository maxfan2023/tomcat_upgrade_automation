# Co-ops Installation Package Runbook

This runbook is for `scripts/co_ops/package/generate_co_ops_installation_package.sh`.

## What the script does

1. Detects `denv`, `benv`, or `penv` from the current build host
2. Checks that the requested `--env` matches the current build host
3. Checks that the target host FQDN is in the predefined allowlist for that env
4. Validates the target host FQDN and required local files
5. Builds the customized co-ops package
6. Copies the package to the target host
7. Unzips the package on the target host
8. Copies `upgrade_co_ops_automation.sh` to the same target directory
9. Makes the remote script executable

## Current host to env mapping

- `gbl25149108.hc.cloud.uk.hsbc` -> `denv`
- `gbl25183782.systems.uk.hsbc` -> `benv`
- `gbl25185915.systems.uk.hsbc` -> `penv`

## Target host rules

- `denv` targets must end with `.hk.hsbc`
- `benv` targets must end with `.systems.uk.hsbc`
- `penv` targets must end with `.systems.uk.hsbc`
- The script accepts only full FQDN input
- The target host must also exist in that env's predefined allowlist inside the matching config file

## Env input rule

You must pass `--env denv`, `--env benv`, or `--env penv`.

The script then checks both:

- the requested env matches the current build host
- the target host belongs to that env allowlist

## Authentication rules

- `denv`: `ssh/scp` may ask for a password
- `benv`: `ssh/scp` should use key-based login
- `penv`: `ssh/scp` should use key-based login

## Remote directory rule

The script always uses:

```text
/opt/abinitio/tmp/co_ops_<version_without_dots>
```

Example:

- version `4.4.3.3` -> `/opt/abinitio/tmp/co_ops_4433`
- version `4.4.4.5` -> `/opt/abinitio/tmp/co_ops_4445`

## Supported steps

- `step_1` detect env from current build host and validate target host
- `step_2` validate local prerequisites
- `step_3` build package
- `step_4` verify generated package
- `step_5` create remote version directory
- `step_6` transfer package
- `step_7` unzip package
- `step_8` transfer `upgrade_co_ops_automation.sh`
- `step_9` chmod remote script and verify remote directory

## Common commands

Dry-run in `denv`:

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv gbl25149199.hk.hsbc 4.4.3.3 --dry-run
```

Dry-run in `benv` without pauses:

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env benv gbl25183799.systems.uk.hsbc 4.4.3.3 --dry-run --auto-continue
```

Real run in `penv`:

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env penv gbl25185999.systems.uk.hsbc 4.4.3.3
```

Resume from package transfer:

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env benv gbl25183799.systems.uk.hsbc 4.4.3.3 --from-step step_6
```

Run a new version:

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv gbl25149199.hk.hsbc 4.4.4.5 --auto-continue
```

## Dry-run behavior

- The script still performs argument parsing, env detection, config loading, and logging
- Workflow commands are printed exactly as they would run
- Workflow commands are not executed in `--dry-run`
- In `--dry-run`, the script also skips runtime lock creation
- In `--dry-run`, the script also skips current build host enforcement, so you can preview commands from a laptop or other non-build host

## Failure behavior

- The script runs with `set -Eeuo pipefail`
- Any failing command inside a step stops the script immediately
- If a step fails, later steps are not executed
- The error is written to the log file

## Logs

Logs are written under:

```text
./logs/
```

Old log files older than 90 days are removed automatically.

## Operator checklist

Before a real run:

1. Log in to the correct build host for the environment
2. Confirm the target host FQDN belongs to that environment
3. Confirm the target host is present in that env's allowlist config
4. Confirm `upgrade_co_ops_automation.sh` exists in the configured local path
5. Run one `--dry-run` first and review the printed commands
6. Start the real run

If a run fails:

1. Read the latest log file under `logs/`
2. Fix the blocking issue
3. Resume from the failed step with `--from-step`
