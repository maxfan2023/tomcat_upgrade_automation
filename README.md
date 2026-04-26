# Ab Initio Operations Automation Scripts

This repository is an Ab Initio operations automation workspace.  
It stores multiple independent automation scripts (not just one Tomcat workflow), and each script has its own purpose, config, and runbook.

Current scripts are **on the same level**:
- JDK upgrade automation: `scripts/jdk/upgrade_jdk.sh`
- Tomcat upgrade automation: `scripts/tomcat/tomcat_upgrade.sh`
- Co-ops package build & transfer: `scripts/co_ops/package/generate_co_ops_installation_package.sh`
- Co-ops target-host upgrade: `scripts/co_ops/upgrade/upgrade_co_ops_automation.sh`

Future scripts for other Ab Initio operational tasks can be added under `scripts/`, `configs/`, and `docs/` using the same pattern.

## Files

- `scripts/jdk/upgrade_jdk.sh`: main JDK upgrade automation entrypoint
- `scripts/tomcat/tomcat_upgrade.sh`: main Tomcat automation entrypoint
- `scripts/co_ops/package/generate_co_ops_installation_package.sh`: build and transfer a customized co-ops package for one target host
- `scripts/co_ops/upgrade/upgrade_co_ops_automation.sh`: run the co-ops upgrade workflow on the target host
- `configs/jdk/jdk_upgrade_<env>.conf`: env-specific settings for the JDK workflow
- `configs/tomcat/default.conf`: public-safe sample configuration for the Tomcat workflow
- `configs/co_ops/package/co_ops_<env>.conf`: env-specific settings for the co-ops package workflow
- `configs/co_ops/upgrade/co_ops_upgrade_<env>.conf`: env-specific settings for the co-ops upgrade workflow

## Repository Layout

The repository keeps a canonical copy of each script and config file under `scripts/`, `configs/`, and `docs/`.  
Root-level shortcut files are intentionally removed, so always use the canonical paths above.  
When new automation modules are added, place them in the matching subfolder under `scripts/`, `configs/`, and `docs/`, and document them in this README.

## JDK Upgrade

The JDK workflow upgrades the Ab Initio Java runtime symlinks on the current application host, verifies the active Java version, archives the old JDK directory, and runs the configured PostgreSQL DB-server JDK update commands.

### Usage

```bash
./scripts/jdk/upgrade_jdk.sh --help
./scripts/jdk/upgrade_jdk.sh --list-steps
./scripts/jdk/upgrade_jdk.sh --env dev --dry-run
./scripts/jdk/upgrade_jdk.sh --env uat --java-version 11.0.31 --auto-continue
./scripts/jdk/upgrade_jdk.sh --env prod --from-step step_8
./scripts/jdk/upgrade_jdk.sh --env prod-cont --jdk-archive zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64
./scripts/jdk/upgrade_jdk.sh --env dev --config /path/to/jdk_upgrade_dev.conf --dry-run
```

### Safe Defaults

`--java-version` is the semantic Java version, such as `11.0.31`; the installer archive is configured separately with `DEFAULT_JDK_ARCHIVE` or overridden with `--jdk-archive`.
The script runs `step_1` through `step_9` by default and supports `--from-step step_N` for restart.
Before updating symlinks, it records the current `jdk11` symlink target and only archives that old directory after the target version is verified.
It refuses to archive or delete the target JDK directory as the old JDK.
`DELETE_OLD_JDK_AFTER_ARCHIVE` controls whether the old directory is removed after its `.tar.gz` archive is created.
`prod-cont` skips application service stop/start by default because its config has empty service command arrays.
DB host updates are executed serially over SSH and stop at the first failure.
Logs are written under `logs/`, error logs use the same name with `.err`, and files older than 90 days are removed automatically.

## Tomcat Upgrade

The Tomcat workflow automates versioned runtime upgrades for configured Ab Initio environments.

### Usage

```bash
./scripts/tomcat/tomcat_upgrade.sh --help
./scripts/tomcat/tomcat_upgrade.sh --dry-run
./scripts/tomcat/tomcat_upgrade.sh --backup-flag yes --dry-run
./scripts/tomcat/tomcat_upgrade.sh --backup-flag yes --auto-continue --dry-run
./scripts/tomcat/tomcat_upgrade.sh --env ienv,denv --version 9.0.117
./scripts/tomcat/tomcat_upgrade.sh --env ienv --version 9.0.117 --auto-continue
./scripts/tomcat/tomcat_upgrade.sh --from-step step_9
./scripts/tomcat/tomcat_upgrade.sh --cleanup
./scripts/tomcat/tomcat_upgrade.sh --config /path/to/your.conf --dry-run
```

### Safe Defaults

Step `1` through step `11` run by default.
`--auto-continue` disables the per-step confirmation prompts.
`--backup-flag yes` adds an extra full backup of the entire `abinitio-app-hub/apps` directory between step `1` and step `2`.
Step `13` and step `14` only run when you add `--cleanup`.
Step `14` removes dated backup directories and keeps the `.tar.gz` archives.
Step `11` purges `bin`, `conf`, `logs`, `temp`, `webapps`, and `work` under the configured app targets before service startup.
`logs`, `temp`, and `work` are restored from the matching `_org` directories when differences are detected, and are also verified in step `10`.
Step `6` runs the Tomcat `version.sh` check after sourcing the matching environment profile.
Step `2`, `4`, `5`, `6`, `7`, and `11` print `ls -lrth` for the apps directory at the end of the step for visibility.
`penv-cont` reuses the `penv` filesystem paths, but skips service stop and start.

### Config Notes

The config file is sourced by the script, so you can copy `configs/tomcat/default.conf` and change paths, profile files, runner scripts, purge targets, or optional health-check hooks without editing the script itself.
The tracked `default.conf` intentionally uses generic example paths for a public repository; replace them with your real environment values before a production run.

## Upgrade Co Ops

The co-ops workflows are peers to Tomcat upgrade and cover package preparation and target-host execution independently.

### co ops installation package generation

```bash
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv gbl25149199.hk.hsbc 4.4.3.3 --dry-run
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env benv gbl25183799.systems.uk.hsbc 4.4.3.3 --auto-continue
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env penv gbl25185999.systems.uk.hsbc 4.4.3.3 --from-step step_6
./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv --config /path/to/co_ops_denv.conf gbl25149199.hk.hsbc 4.4.3.3 --dry-run
```

Notes

`target_host` must be passed as a full FQDN.
`--env` is required, and the script checks that it matches the current build host.
`-c` or `--config` lets you override the default env config file.
Even when `--config` is used, `--env` is still required for package workflow validation.
The target host must be present in the predefined allowlist inside the matching `configs/co_ops/package/co_ops_<env>.conf`.
`denv` uses interactive `ssh/scp` password prompts; `benv` and `penv` assume key-based login.
The remote directory is version-parameterized as `/opt/abinitio/tmp/co_ops_<version_without_dots>`.
Logs are written under `logs/` and files older than 90 days are removed automatically.
A step-by-step operator guide lives in `docs/runbooks/co_ops/CO_OPS_RUNBOOK.md`.
In `--dry-run`, the script skips current build host enforcement and only prints workflow commands.

### conduct co ops on target server

```bash
./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh 4.4.3.3 --dry-run
./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh --env benv 4.4.3.3 --auto-continue
./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh 4.4.3.3 --from-step step_6
./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh --config /path/to/co_ops_upgrade.conf 4.4.3.3 --dry-run
```

Notes

`-c` or `--config` lets you override the default env config file.
The matching env config files live under `configs/co_ops/upgrade/`.
Logs are written under `logs/` and error logs under `logs` with `.err` suffix.
Lock and runtime state files are written under `.state/`.
