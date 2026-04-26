# Repository Layout

This repository stores a single canonical copy of each workflow asset under grouped directories.

## Layout

```text
scripts/
  jdk/
    upgrade_jdk.sh
  tomcat/
    tomcat_upgrade.sh
  co_ops/
    package/
      generate_co_ops_installation_package.sh
    upgrade/
      upgrade_co_ops_automation.sh

configs/
  jdk/
    jdk_upgrade_<env>.conf
  tomcat/
    default.conf
  co_ops/
    package/
      co_ops_<env>.conf
    upgrade/
      co_ops_upgrade_<env>.conf

docs/
  prompts/
    tomcat/
    co_ops/
  runbooks/
    co_ops/
```

## Runtime Paths

- Scripts write logs to the shared `logs/` directory in the repository root.
- Scripts write lock and state files to the shared `.state/` directory in the repository root.
- Scripts resolve their configs directly from `configs/` without compatibility symlinks.

## Adding New Workflows

When you add a new automation later, follow the same pattern:

1. Put the executable script under `scripts/<domain>/<workflow>/`.
2. Put that workflow's config files under `configs/<domain>/<workflow>/`.
3. Put prompt documents under `docs/prompts/<domain>/`.
4. Put operator runbooks under `docs/runbooks/<domain>/`.
5. Update `README.md` if you add a new canonical entrypoint or change how an existing script is launched.
