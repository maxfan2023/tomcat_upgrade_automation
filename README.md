# Tomcat Upgrade Automation

This repository contains a configurable upgrade script for a Tomcat upgrade workflow used in an Ab Initio-style application hub layout.

## Files

- `tomcat_upgrade.sh`: main automation entrypoint
- `configs/default.conf`: public-safe sample configuration you can customize for your environment

## Safe Defaults

- Step `1` through step `11` run by default.
- By default the script pauses after each completed step and waits for `yes` before continuing.
- `--auto-continue` disables the per-step confirmation prompts.
- `--backup-flag yes` adds an extra full backup of the entire `abinitio-app-hub/apps` directory between step `1` and step `2`.
- Step `13` and step `14` only run when you add `--cleanup`.
- Step `14` removes dated backup directories and keeps the `.tar.gz` archives.
- Step `11` purges `bin`, `conf`, `logs`, `temp`, `webapps`, and `work` under the configured app targets before service startup.
- `logs`, `temp`, and `work` are restored from the matching `_org` directories when differences are detected, and are also verified in step `10`.
- Step `6` runs the Tomcat `version.sh` check after sourcing the matching environment profile.
- Step `2`, `4`, `5`, `6`, `7`, and `11` print `ls -lrth` for the apps directory at the end of the step for visibility.
- `penv-cont` reuses the `penv` filesystem paths, but skips service stop and start.

## Usage

```bash
./tomcat_upgrade.sh --help
./tomcat_upgrade.sh --dry-run
./tomcat_upgrade.sh --backup-flag yes --dry-run
./tomcat_upgrade.sh --backup-flag yes --auto-continue --dry-run
./tomcat_upgrade.sh --env ienv,denv --version 9.0.117
./tomcat_upgrade.sh --env ienv --version 9.0.117 --auto-continue
./tomcat_upgrade.sh --from-step step_9
./tomcat_upgrade.sh --cleanup
./tomcat_upgrade.sh --config /path/to/your.conf --dry-run
```

## Config Notes

The config file is sourced by the script, so you can copy `configs/default.conf` and change paths, profile files, runner scripts, purge targets, or optional health-check hooks without editing the script itself. The tracked `default.conf` intentionally uses generic example paths for a public repository; replace them with your real environment values before a production run.
