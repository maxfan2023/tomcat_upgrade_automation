# Prompt to upgrade JDK version automatically

## Upgrade Process

### Step 0: Check current JDK installation file

for dev env : detect jdk installation file under path zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz
if it doesn't exist, prompt user to download and install JDK 11.0.31 from nexus repository and place it under the path mentioned above, then exit the upgrade process.

for uat env : detect jdk installation file under path zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz
if it doesn't exist, prompt user to download and install JDK 11.0.31 from nexus repository and place it under the path mentioned above, then exit the upgrade process.

for prod env : detect jdk installation file under path zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz
if it doesn't exist, prompt user to download and install JDK 11.0.31 from nexus repository and place it under the path mentioned above, then exit the upgrade process.

for prod-cont env : detect jdk installation file under path zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz
if it doesn't exist, prompt user to download and install JDK 11.0.31 from nexus repository and place it under the path mentioned above, then exit the upgrade process.

### Step 1: Check current java version

for dev env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.30 2026-01-20 LTS
OpenJDK Runtime Environment Zulu11.86+20-SA (build 11.0.30+7-LTS)
OpenJDK 64-Bit Server VM Zulu11.86+20-SA (build 11.0.30+7-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then prompt user that the JDK version is already up to date and exit the upgrade process.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK version is outdated and proceed to step 2.

for uat env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.30 2026-01-20 LTS
OpenJDK Runtime Environment Zulu11.86+20-SA (build 11.0.30+7-LTS)
OpenJDK 64-Bit Server VM Zulu11.86+20-SA (build 11.0.30+7-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then prompt user that the JDK version is already up to date and exit the upgrade process.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK version is outdated and proceed to step 2.

for prod env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.30 2026-01-20 LTS
OpenJDK Runtime Environment Zulu11.86+20-SA (build 11.0.30+7-LTS)
OpenJDK 64-Bit Server VM Zulu11.86+20-SA (build 11.0.30+7-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then prompt user that the JDK version is already up to date and exit the upgrade process.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK version is outdated and proceed to step 2.

for prod-cont env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.30 2026-01-20 LTS
OpenJDK Runtime Environment Zulu11.86+20-SA (build 11.0.30+7-LTS)
OpenJDK 64-Bit Server VM Zulu11.86+20-SA (build 11.0.30+7-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then prompt user that the JDK version is already up to date and exit the upgrade process.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK version is outdated and proceed to step 2.

### Step 2: stop abinitio services on application server

for dev env : run following command to stop abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh stop all-services
/FCR_APP/abinitio/management/scripts/denv.abinitio.runner.sh stop all-services
```

for uat env : run following command to stop abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/benv.abinitio.runner.sh stop all-services
```

for prod env : run following command to stop abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/penv.abinitio.runner.sh stop all-services
```

for cont env : it doesn't need to run any command to stop abinitio services on application server

### Step 3: install new JDK

for dev env : run following command to install new JDK
```
cd /FCR_APP/abinitio/software/java/jdk11
ls -lrth /FCR_APP/abinitio/software/java/jdk11
tar -xzf zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz -C /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
```

for uat env : run following command to install new JDK
```
cd /FCR_APP/abinitio/software/java/jdk11
ls -lrth /FCR_APP/abinitio/software/java/jdk11
tar -xzf zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz -C /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
```

for prod env : run following command to install new JDK
```
cd /FCR_APP/abinitio/software/java/jdk11
ls -lrth /FCR_APP/abinitio/software/java/jdk11
tar -xzf zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz -C /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
```

for prod-cont env : run following command to install new JDK
```
cd /FCR_APP/abinitio/software/java/jdk11
ls -lrth /FCR_APP/abinitio/software/java/jdk11
tar -xzf zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz -C /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
```

### Step 4: Update symbolic link to point to new JDK

for dev env : run following command to update symbolic link to point to new JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
unlink jdk11
unlink jdk1.8.0_191
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk1.8.0_191
chmod -R 2755 zulu11.88.18-sa-jdk11.0.31-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for uat env : run following command to update symbolic link to point to new JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
unlink jdk11
unlink jdk1.8.0_191
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk1.8.0_191
chmod -R 2755 zulu11.88.18-sa-jdk11.0.31-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for prod env : run following command to update symbolic link to point to new JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
unlink jdk11
unlink jdk1.8.0_191
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk1.8.0_191
chmod -R 2755 zulu11.88.18-sa-jdk11.0.31-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for prod-cont env : run following command to update symbolic link to point to new JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
unlink jdk11
unlink jdk1.8.0_191
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk11
ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 jdk1.8.0_191
chmod -R 2755 zulu11.88.18-sa-jdk11.0.31-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

### Step 5: Archive old JDK

for dev env : run following command to archive old JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for uat env : run following command to archive old JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for prod env : run following command to archive old JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

for prod-cont env : run following command to archive old JDK
```
cd /FCR_APP/abinitio/java
ls -lrth /FCR_APP/abinitio/java
tar -czf zulu11.86.20-sa-jdk11.0.30-linux_x64_<YYYYMMDD>.tar.gz zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
rm -rf zulu11.86.20-sa-jdk11.0.30-linux_x64
ls -lrth /FCR_APP/abinitio/java
```

### Step 6: Check current java version

for dev env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.

for uat env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.

for prod env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.

for prod-cont env : run following command to get current java version
```
$ /FCR_APP/abinitio/java/jdk11/bin/java --version
openjdk 11.0.31 2026-04-21 LTS
OpenJDK Runtime Environment Zulu11.88+18-SA (build 11.0.31+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.88+18-SA (build 11.0.31+11-LTS, mixed mode)
```

if the java version matches the expected version 11.0.31, then continue to next step.
if the java version does not match the expected version 11.0.31, then prompt user that the JDK upgrade process has failed and exit the upgrade process.

### Step 7: update the JDK used on PostgreSQL database server

for dev env :

first , copy the new JDK folder from application server to database server by running following command
```
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/java/
```
then copy the PostgreSQL JDK upgrade script and config to database server by running following command
```
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_dev.conf gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_dev.conf
ssh -q gbl25152435.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
```
then run following command to update the JDK used on PostgreSQL database server
```
ssh -q gbl25152435.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env dev --config /opt/clouseau/jdk_pg_upgrade_dev.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
```

for uat env :

first , copy the new JDK folder from application server to database server by running following command
```
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25152143.hc.cloud.uk.hsbc:/opt/clouseau/java/
```
then copy the PostgreSQL JDK upgrade script and config to database server by running following command
```
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25152143.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_uat.conf gbl25152143.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_uat.conf
ssh -q gbl25152143.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
```
then run following command to update the JDK used on PostgreSQL database server
```
ssh -q gbl25152143.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env uat --config /opt/clouseau/jdk_pg_upgrade_uat.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
```

for prod env :

first , copy the new JDK folder from application server to database server by running following command
```
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25164752.hc.cloud.uk.hsbc:/opt/clouseau/java/
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25164753.hc.cloud.uk.hsbc:/opt/clouseau/java/
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25165194.hc.cloud.uk.hsbc:/opt/clouseau/java/
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25165195.hc.cloud.uk.hsbc:/opt/clouseau/java/
```
then copy the PostgreSQL JDK upgrade script and config to database server by running following command
```
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25164752.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_prod.conf gbl25164752.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_prod.conf
ssh -q gbl25164752.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25164753.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_prod.conf gbl25164753.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_prod.conf
ssh -q gbl25164753.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25165194.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_prod.conf gbl25165194.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_prod.conf
ssh -q gbl25165194.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25165195.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_prod.conf gbl25165195.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_prod.conf
ssh -q gbl25165195.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
```
then, run following command to update the JDK used on PostgreSQL database server
```
ssh -q gbl25164752.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env prod --config /opt/clouseau/jdk_pg_upgrade_prod.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
ssh -q gbl25164753.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env prod --config /opt/clouseau/jdk_pg_upgrade_prod.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
ssh -q gbl25165194.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env prod --config /opt/clouseau/jdk_pg_upgrade_prod.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
ssh -q gbl25165195.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env prod --config /opt/clouseau/jdk_pg_upgrade_prod.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
```

for prod-cont env :

first , copy the new JDK folder from application server to database server by running following command
```
scp -qr /FCR_APP/abinitio/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25164751.hc.cloud.uk.hsbc:/opt/clouseau/java
```
then copy the PostgreSQL JDK upgrade script and config to database server by running following command
```
scp -q scripts/jdk/upgrade_jdk_on_db.sh gbl25164751.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh
scp -q configs/jdk/jdk_pg_upgrade_prod-cont.conf gbl25164751.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_prod-cont.conf
ssh -q gbl25164751.hc.cloud.uk.hsbc -C "chmod +x /opt/clouseau/upgrade_jdk_on_db.sh"
```
then, run following command to update the JDK used on PostgreSQL database server
```
ssh -q gbl25164751.hc.cloud.uk.hsbc -C "/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env prod-cont --config /opt/clouseau/jdk_pg_upgrade_prod-cont.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue"
```

### Step 8: start abinitio services on application server

for dev env : run following command to start abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh start all-services
/FCR_APP/abinitio/management/scripts/denv.abinitio.runner.sh start all-services
```

for uat env : run following command to start abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/benv.abinitio.runner.sh start all-services
```

for prod env : run following command to start abinitio services on application server
```
cd /FCR_APP/abinitio/tmp
/FCR_APP/abinitio/management/scripts/penv.abinitio.runner.sh start all-services
```

for cont env : it doesn't need to run any command to start abinitio services on application server



# Requirement Detail of the script

## 2.1 define one script and respective configuration files based on different envs, so that it's easy to change the setting in configuration files, no need to update script, when calling the script, we can specify the config file location

## 2.2 it support dry-run mode (only print out commands) and debug mode

## 2.3 print commands before executing the commands in each step

## 2.4 all outputs should be logged to log file, and the log file should be rotated by date, for example, jdk_<JAVA_VERSION>_update_20240624.log, and logs should be put into certain directory, it can delete the logs which are older than 90 days to save the disk space automatically, when the script completes, it should print the log file location to user, so that user can check the log file for details of the upgrade process, and if there's any error, user can check the log file for error message and troubleshooting.

## 2.5 if there's any error in any step, the script should stop and print the error message to log file

## 2.6 the script should be idempotent, which means if we run the script multiple times, it should not cause any issue, and the result should be the same as running the script once

## 2.7 add more comments in script

## 2.8 add emoji when printing the log message

## 2.9 it can support to start the script from a specified step, for example, if we want to start the script from step 9, we can pass the parameter "step_9" to the script, and the script will start from step 9, and execute the following steps

## 2.10, in my example, i use zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz as example, the jdk version is 11.0.31, it should also support to update to other versions.

## 2.11. try to parameterize the script as much as possible, even some steps are same in each env.
