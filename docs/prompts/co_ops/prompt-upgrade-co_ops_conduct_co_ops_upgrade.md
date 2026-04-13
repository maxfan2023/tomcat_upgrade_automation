As one linux and abinitio export, please develop one script to automate the co_ops 4.4.3.3 upgrade process and configuration changes.

# 1. The upgrade process is as below

## Step 1 Verify the co-ops installation package is in place in the target host

for denv:
the installation package should be in place in the target host in following location, if not throw error

/opt/abinitio/tmp/co_ops_4433/ai_build_package_${BUILDHOST}_denv.tgz

for benv:
the installation package should be in place in the target host in following location, if not throw error

/opt/abinitio/tmp/co_ops_4433/ai_build_package_${BUILDHOST}_benv.tgz

for penv:
the installation package should be in place in the target host in following location, if not throw error

/opt/abinitio/tmp/co_ops_4433/ai_build_package_${BUILDHOST}_penv.tgz

${BUILDHOST} is the current host name, which can be obtained with command "hostname -f", like gbl25149199.hk.hsbc,gbl25183799.systems.uk.hsbc,gbl25185999.systems.uk.hsbc

## Step 2 Run the upgrade script to upgrade co-ops 

for denv:
run the upgrade script with following command
cd /opt/abinitio/tmp/co_ops_4433 && ./ai_build_package/scripts/coop-upgrade.ksh -c

for benv:
run the upgrade script with following command
cd /opt/abinitio/tmp/co_ops_4433 && ./ai_build_package/scripts/coop-upgrade.ksh -c

for penv:
run the upgrade script with following command
cd /opt/abinitio/tmp/co_ops_4433 && ./ai_build_package/scripts/coop-upgrade.ksh -c

## Step 3 Validate the co-ops upgrade result with admin profile

for denv:
run the validation script with following command
export AB_HOME=/opt/abinitio/denv/abinitio/abinitio-V4-4-3-3
export PATH=$AB_HOME/bin:$PATH
echo $PATH
installation-test
ab-key show

for benv:
run the validation script with following command
export AB_HOME=/opt/abinitio/benv/abinitio/abinitio-V4-4-3-3
export PATH=$AB_HOME/bin:$PATH
echo $PATH
installation-test
ab-key show

for penv:
run the validation script with following command
export AB_HOME=/opt/abinitio/penv/abinitio/abinitio-V4-4-3-3
export PATH=$AB_HOME/bin:$PATH
echo $PATH
installation-test
ab-key show

## Step 4 Create source profile.

for denv:
create source profile with following command

cp /opt/abinitio/management/scripts/ab.profile.denv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.denv-V4-4-3-3
scan line starts with "export AB_HOME" in the new created profile, and update the AB_HOME path to /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3, if the line is not found, throw error
then compare /opt/abinitio/management/scripts/ab.profile.denv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.denv-V4-4-3-3 with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.

for benv:
create source profile with following command
cp /opt/abinitio/management/scripts/ab.profile.benv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.benv-V4-4-3-3
scan line starts with "export AB_HOME" in the new created profile, and update the AB_HOME path to /opt/abinitio/benv/abinitio/abinitio-V4-4-3-3, if the line is not found, throw error
then compare /opt/abinitio/management/scripts/ab.profile.benv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.benv-V4-4-3-3 with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.

for penv:
create source profile with following command
cp /opt/abinitio/management/scripts/ab.profile.penv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.penv-V4-4-3-3
scan line starts with "export AB_HOME" in the new created profile, and update the AB_HOME path to /opt/abinitio/penv/abinitio/abinitio-V4-4-3-3, if the line is not found, throw error
then compare /opt/abinitio/management/scripts/ab.profile.penv-V4-4-1-0 /opt/abinitio/management/scripts/ab.profile.penv-V4-4-3-3 with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.

## Step 5 Update abinitiorc file

for denv:
update abinitiorc file with following command

cp /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY>
scan line starts with "AB_JAVA_HOME" in /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc, then update the value after ":" to "/opt/abinitio/java/jdk11".

then compare /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY> with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.

for example, if there are following two line in the abinitiorc file

AB_JAVA_HOME                         @ abinitio-dev-cdp63-en : /hadoop/java
AB_JAVA_HOME                                            : /hadoop/java/bin

it should update to

AB_JAVA_HOME                         @ abinitio-dev-cdp63-en : /opt/abinitio/java/jdk11
AB_JAVA_HOME                                            : /opt/abinitio/java/jdk11

<DDMMYYYY> is the date when the backup is taken, for example, if the backup is taken on 1st June 2024, DDMMYYYY is 01062024

for benv:
update abinitiorc file with following command

cp /opt/abinitio/benv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/benv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY>
scan line starts with "AB_JAVA_HOME" in /opt/abinitio/benv/abinitio/abinitio-V4-4-3-3/config/abinitiorc, then update the value after ":" to "/opt/abinitio/java/jdk11".
then compare /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY> with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.
for example, if there are following two line in the abinitiorc file

AB_JAVA_HOME                         @ abinitio-dgw-uat-hdp11 : /hadoop/java
AB_JAVA_HOME                                            : /hadoop/java/jdk11

it should update to

AB_JAVA_HOME                         @ abinitio-dgw-uat-hdp11 : /opt/abinitio/java/jdk11
AB_JAVA_HOME                                            : /opt/abinitio/java/jdk11

<DDMMYYYY> is the date when the backup is taken, for example, if the backup is taken on 1st June 2024, DDMMYYYY is 01062024

for penv:
update abinitiorc file with following command

cp /opt/abinitio/penv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/penv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY>
scan line starts with "AB_JAVA_HOME" in /opt/abinitio/penv/abinitio/abinitio-V4-4-3-3/config/abinitiorc, then update the value after ":" to "/opt/abinitio/java/jdk11".
then compare /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc /opt/abinitio/denv/abinitio/abinitio-V4-4-3-3/config/abinitiorc_bkp_<DDMMYYYY> with diff command to show the changes, if there's no change, throw error, if there's change, print the change to log file.

for example, if there are following two line in the abinitiorc file

AB_JAVA_HOME                                            : /hadoop/java/jdk11
AB_JAVA_HOME                         @ abinitio-prod-hdp07-en : /hadoop/java
AB_JAVA_HOME                         @ abinitio-prod-hdp07-dn : /hadoop/java

it should update to

AB_JAVA_HOME                                            : /opt/abinitio/java/jdk11
AB_JAVA_HOME                         @ abinitio-prod-hdp07-en : /opt/abinitio/java/jdk11
AB_JAVA_HOME                         @ abinitio-prod-hdp07-dn : /opt/abinitio/java/jdk11

<DDMMYYYY> is the date when the backup is taken, for example, if the backup is taken on 1st June 2024, DDMMYYYY is 01062024

## Step 6 Validate the co-ops upgrade result with batch profile

for denv:
run the validation script with batch account fap41-abibatch-01 (please use dzdo - /bin/su fap41-abibatch command , not sudo ) to following command

source /opt/abinitio/management/scripts/ab.profile.denv-V4-4-3-3
installation-test
ab-key show

for benv:
run the validation script with batch account fap41-abibatch-01 (please use dzdo - /bin/su fap41-abibatch command , not sudo ) to following command
source /opt/abinitio/management/scripts/ab.profile.benv-V4-4-3-3
installation-test
ab-key show

for penv:
run the validation script with batch account fap01-abibatch-01 (please use dzdo - /bin/su fap01-abibatch command , not sudo ) to following command
source /opt/abinitio/management/scripts/ab.profile.penv-V4-4-3-3
installation-test
ab-key show

as curent login user is fap41-abiadmin (in denv,denv) or fap01-abiadmin (in penv), it needs to run "abibatch" command to switch to batch account before running above above validation command. so the source,installation-test and ab-key show command should be run in batch account, not in current login user.


## Step 7 Archive the tomcat 10 directory 

for denv:
tar -czf /opt/abinitio/denv/abinitio-app-hub/apps/catalina-base-10.1.tgz /opt/abinitio/denv/abinitio-app/hub/apps/catalina-base-10.1
tar -czf /opt/abinitio/denv/abinitio-app-hub/apps/catalina-base-10.1-tmplt.tgz /opt/abinitio/denv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
tar -czf /opt/abinitio/denv/abinitio-app-hub/apps/catalina-home-10.1.tgz /opt/abinitio/denv/abinitio-app/hub/apps/catalina-home-10.1

rm -rf /opt/abinitio/denv/abinitio-app/hub/apps/catalina-base-10.1
rm -rf /opt/abinitio/denv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
rm -rf /opt/abinitio/denv/abinitio-app/hub/apps/catalina-home-10.1

for benv:
tar -czf /opt/abinitio/benv/abinitio-app-hub/apps/catalina-base-10.1.tgz /opt/abinitio/benv/abinitio-app/hub/apps/catalina-base-10.1
tar -czf /opt/abinitio/benv/abinitio-app-hub/apps/catalina-base-10.1-tmplt.tgz /opt/abinitio/benv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
tar -czf /opt/abinitio/benv/abinitio-app-hub/apps/catalina-home-10.1.tgz /opt/abinitio/benv/abinitio-app/hub/apps/catalina-home-10.1

rm -rf /opt/abinitio/benv/abinitio-app/hub/apps/catalina-base-10.1
rm -rf /opt/abinitio/benv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
rm -rf /opt/abinitio/benv/abinitio-app/hub/apps/catalina-home-10.1

for penv:
tar -czf /opt/abinitio/penv/abinitio-app-hub/apps/catalina-base-10.1.tgz /opt/abinitio/penv/abinitio-app/hub/apps/catalina-base-10.1
tar -czf /opt/abinitio/penv/abinitio-app-hub/apps/catalina-base-10.1-tmplt.tgz /opt/abinitio/penv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
tar -czf /opt/abinitio/penv/abinitio-app-hub/apps/catalina-home-10.1.tgz /opt/abinitio/penv/abinitio-app/hub/apps/catalina-home-10.1

rm -rf /opt/abinitio/penv/abinitio-app/hub/apps/catalina-base-10.1
rm -rf /opt/abinitio/penv/abinitio-app/hub/apps/catalina-base-10.1-tmplt
rm -rf /opt/abinitio/penv/abinitio-app/hub/apps/catalina-home-10.1

# 2. the requirement of the script is as below

## 2.0 curent shell script is the one "upgrade_co_ops_automation.sh " mentioned in prompt file "docs/prompts/co_ops/prompt-upgrade-co_ops_generate_installation_package.md"

## 2.1 define one script and respective configuration files based on different envs, so that it's easy to change the setting in configuration files, no need to update script

## 2.2 it should support dry-run mode (only print out commands) and debug mode. in debug mode, it will print out the commands, it won't execute the commands.  

## 2.3 print commands before executing the commands in each step

## 2.4 all outputs should be logged to log file, and the log file should be rotated by date, and logs should be put into certain directory, it can delete the logs which are older than 90 days to save the disk space automatically.

## 2.5 if there's any error in any step, the script should stop and print the error message to log file

## 2.6 the script should be idempotent, which means if we run the script multiple times, it should not cause any issue, and the result should be the same as running the script once

## 2.7 add more comments in script

## 2.8 add emoji when printing the log message

## 2.9 it can support to start the script from a specified step, for example, if we want to start the script from step 3, we can pass the parameter "step_3" to the script, and the script will start from step 3, and execute the following steps

## 2.10, in my example, i use 4.4.3.3 as example, it should also support to update to other versions, for example, 4.4.3.3, we can pass the parameter "4.4.3.3" to the script, and the script will generate the package for the version

## 2.11, try to parameterize the script as much as possible

## 2.12, after each step, please stop and wait for user input yes to continue to the next step, if user input other than yes, the script should stop and print the message "script stopped by user" to log file, and exit the script.

## 2.13, there is one input prameter for the script, which is the BUILDHOST, for example, gbl25149108.hc.cloud.uk.hsbc, gbl25183782.systems.uk.hsbc, gbl25185915.systems.uk.hsbc, the script should check the input parameter and determine which env it is, and execute the corresponding commands based on the env.

## 2.14, there is one input paramater for the script, which is the co-ops version number, for example, 4.4.3.3, the script should check the input parameter and determine which version it is, and execute the corresponding commands based on the version

## 2.15, there is one input parameter for the script, like --auto-continue, if this parameter is passed to the script, it will automatically continue to the next step without waiting for user input, and it will print the message "auto continue to the next step" to log file before continue to the next step.

## 2.16, the script should be able to run in linux environment, especially for RHEL8 x86-linux64, and it should be compatible with bash
