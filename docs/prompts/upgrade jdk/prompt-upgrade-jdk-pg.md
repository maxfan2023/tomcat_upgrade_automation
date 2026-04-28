# Prompt to upgrade JDK version on postgreSQL server automatically

## Upgrade Process



### PG Step 1 (pg_step_1): Check current JDK installation folder
for dev env : run following command to check current JDK installation folder
```
ls -lrth /opt/clouseau/java/zulu11.88.18-sa-jdk11.0.31-linux_x64
```
ensure the JDK installation folder name is correct and matches the expected new JDK version 11.0.31, if not, prompt user that the JDK upgrade process has failed and exit the upgrade process.

for uat env : run following command to check current JDK installation folder
```
ls -lrth /opt/clouseau/java/zulu11.88.18-sa-jdk11.0.31-linux_x64
```
ensure the JDK installation folder name is correct and matches the expected new JDK version 11.0.31, if not, prompt user that the JDK upgrade process has failed and exit the upgrade process.

for prod env : run following command to check current JDK installation folder
```
ls -lrth /opt/clouseau/java/zulu11.88.18-sa-jdk11.0.31-linux_x64
```
ensure the JDK installation folder name is correct and matches the expected new JDK version 11.0.31, if not, prompt user that the JDK upgrade process has failed and exit the upgrade process.

for prod-cont env : run following command to check current JDK installation folder
```
ls -lrth /opt/clouseau/java/zulu11.88.18-sa-jdk11.0.31-linux_x64
```
ensure the JDK installation folder name is correct and matches the expected new JDK version 11.0.31, if not, prompt user that the JDK upgrade process has failed and exit the upgrade process.


### PG Step 2 (pg_step_2): Update symbolic link to point to new JDK


for dev env : run following command to update symbolic link to point to new JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
unlink jdk-11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk-11
ls -lrth /opt/clouseau/java
```

for uat env : run following command to update symbolic link to point to new JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
unlink jdk-11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk-11
ls -lrth /opt/clouseau/java
```

for prod env : run following command to update symbolic link to point to new JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
unlink jdk-11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk-11
ls -lrth /opt/clouseau/java
```

for prod-cont env : run following command to update symbolic link to point to new JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
unlink jdk-11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk-11
ls -lrth /opt/clouseau/java
```

### PG Step 3 (pg_step_3): Archive old JDK

for dev env : run following command to archive old JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /opt/clouseau/java
```


for uat env : run following command to archive old JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /opt/clouseau/java
```

for prod env : run following command to archive old JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /opt/clouseau/java
```

for prod-cont env : run following command to archive old JDK
```
cd /opt/clouseau/java
ls -lrth /opt/clouseau/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /opt/clouseau/java
```


### PG Step 4 (pg_step_4): Check current java version

for dev env : run following command to get current java version
```
$ /opt/clouseau/java/jdk-11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.


for uat env : run following command to get current java version
```
$ /opt/clouseau/java/jdk-11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.


for prod env : run following command to get current java version
```
$ /opt/clouseau/java/jdk-11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.


for prod-cont env : run following command to get current java version
```
$ /opt/clouseau/java/jdk-11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.



## Requirement Detail of the script

## 2.1 define one script and respective configuration files based on different envs, so that it's easy to change the setting in configuration files, no need to update script, when calling the script, we can specify the config file location

## 2.2 it should support command line parameters --env, --config, --java-version, --jdk-dir, --old-jdk-basename, --from-step, --dry-run, --debug, --auto-continue, and --list-steps, so that the application server script can call it remotely with explicit version and config values. The PostgreSQL script should display its internal steps as pg_step_1 through pg_step_4; --from-step should prefer pg_step_N while keeping step_N and N as compatible inputs.
