prompt

As one linux and abinitio export, please develop one script to automate the process to build customized co-ops 4.4.3.3 installation in our environment.

# 1. The build process is as below

## Step 1 Build customized co-ops installation package for given host

For denv:
1. current host should be gbl25149108.hc.cloud.uk.hsbc, if it's not throw error
2. build customized co-ops installation package for the given host with following command
cd /FCR_APP/abinitio/tmp
export BUILDHOST=<target_host>
ai_build/scripts.v2/build-package.ksh -t ${BUILDHOST}.hk.hsbc -e denv -b <co_ops_version_number>

<target_host> is one input parameter for the script, and <co_ops_version_number> is the version number of co-ops to be upgraded like 4.4.3.3, which is also an input parameter for the script.

For benv:
1. current host should be gbl25183782.systems.uk.hsbc, if it's not throw error
2. build customized co-ops installation package for the given host with following command
cd /opt/abinitio/tmp
export BUILDHOST=<target_host>
ai_build/scripts.v2/build-package.ksh -x ai_build/build/reference.v2/hostname-hdp11-new-server.xref -t ${BUILDHOST}.systems.uk.hsbc -e benv -b <co_ops_version_number>

<target_host> is one input parameter for the script, and <co_ops_version_number> is the version number of co-ops to be upgraded like 4.4.3.3, which is also an input parameter for the script.

For penv:
1. current host should be gbl25185915.systems.uk.hsbc, if it's not throw error
2. build customized co-ops installation package for the given host with following command
cd /opt/abinitio/tmp
export BUILDHOST=<target_host>
ai_build/scripts.v2/build-package.ksh -x ai_build/build/reference.v2/hostname-hdp07-new-server.xref -t ${BUILDHOST}.systems.uk.hsbc -e penv -b <co_ops_version_number>

<target_host> is one input parameter for the script, and <co_ops_version_number> is the version number of co-ops to be upgraded like 4.4.3.3, which is also an input parameter for the script.

## Step 2 transfer the installation package to the target host and unzip it

For denv:
transfer the package from gbl25149108.hc.cloud.uk.hsbc to <target_host> with following command
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "mkdir -p /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to create the folder
scp -q /FCR_APP/abinitio/tmp/ai_build/tmp/ai_build_package_${BUILDHOST}_denv.tgz fap41-abiadmin@${BUILDHOST}.hk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to create the folder
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "cd /opt/abinitio/tmp/co_ops_4433 && tar -xzf ai_build_package_${BUILDHOST}_denv.tgz && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to unzip the package

For benv:
transfer the package from gbl25183782.systems.uk.hsbc to <target_host> with following command
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "mkdir -p /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to create the folder
scp -q /opt/abinitio/tmp/ai_build/tmp/ai_build_package_${BUILDHOST}_benv.tgz fap41-abiadmin@${BUILDHOST}.systems.uk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to transfer the package
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "cd /opt/abinitio/tmp/co_ops_4433 && tar -xzf ai_build_package_${BUILDHOST}_benv.tgz && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to unzip the package

For penv:
transfer the package from gbl25185915.systems.uk.hsbc to <target_host> with following command
ssh -q fap01-abiadmin@<target_host>.hk.hsbc -C "mkdir -p /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to create the folder
scp -q /opt/abinitio/tmp/ai_build/tmp/ai_build_package_${BUILDHOST}_penv.tgz fap01-abiadmin@${BUILDHOST}.systems.uk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to transfer the package
ssh -q fap01-abiadmin@<target_host>.hk.hsbc -C "cd /opt/abinitio/tmp/co_ops_4433 && tar -xzf ai_build_package_${BUILDHOST}_penv.tgz && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to unzip the package

## Step 3 transfer the upgrade co_ops script to the target host

For denv:
transfer the script from gbl25149108.hc.cloud.uk.hsbc to <target_host> with following command:

scp -q /FCR_APP/abinitio/tmp/upgrade_co_ops_automation.sh fap41-abiadmin@${BUILDHOST}.hk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to transfer the script
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "ls -lrth /opt/abinitio/tmp/co_ops_4433 && chmod +x /opt/abinitio/tmp/co_ops_4433/upgrade_co_ops_automation.sh && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to check the script

For benv:
transfer the script from gbl25183782.systems.uk.hsbc to <target_host> with following command:

scp -q /opt/abinitio/tmp/upgrade_co_ops_automation.sh fap41-abiadmin@${BUILDHOST}.systems.uk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to transfer the script
ssh -q fap41-abiadmin@<target_host>.hk.hsbc -C "ls -lrth /opt/abinitio/tmp/co_ops_4433 && chmod +x /opt/abinitio/tmp/co_ops_4433/upgrade_co_ops_automation.sh && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to check the script

For penv:
transfer the script from gbl25185915.systems.uk.hsbc to <target_host> with following command:

scp -q /opt/abinitio/tmp/upgrade_co_ops_automation.sh fap01-abiadmin@${BUILDHOST}.systems.uk.hsbc:/opt/abinitio/tmp/co_ops_4433, it may ask for password, please input the password to transfer the script
ssh -q fap01-abiadmin@<target_host>.hk.hsbc -C "ls -lrth /opt/abinitio/tmp/co_ops_4433 && chmod +x /opt/abinitio/tmp/co_ops_4433/upgrade_co_ops_automation.sh && ls -lrth /opt/abinitio/tmp/co_ops_4433", it may ask for password, please input the password to check the script

# 2. the requirement of the script is as below

## 2.1 define one script and respective configuration files based on different envs, so that it's easy to change the setting in configuration files, no need to update script

## 2.2 it should support dry-run mode (only print out commands) and debug mode

## 2.3 print commands before executing the commands in each step

## 2.4 all outputs should be logged to log file, and the log file should be rotated by date, and logs should be put into certain directory, it can delete the logs which are older than 90 days to save the disk space automatically.

## 2.5 if there's any error in any step, the script should stop and print the error message to log file

## 2.6 the script should be idempotent, which means if we run the script multiple times, it should not cause any issue, and the result should be the same as running the script once

## 2.7 add more comments in script

## 2.8 add emoji when printing the log message

## 2.9 it can support to start the script from a specified step, for example, if we want to start the script from step 9, we can pass the parameter "step_9" to the script, and the script will start from step 9, and execute the following steps

## 2.10, in my example, i use 4.4.3.3 as example, it should also support to update to other versions, for example, 4.4.3.3, we can pass the parameter "4.4.3.3" to the script, and the script will generate the package for the version

## 2.11, try to parameterize the script as much as possible, especially for path like co_ops_4433, later we may use co_ops_4445, ensure it's parameterized

## 2.12, after each step, please stop and wait for user input yes to continue to the next step, if user input other than yes, the script should stop and print the message "script stopped by user" to log file, and exit the script.

## 2.13, there is one input prameter for the script, which is the target host name, for example, gbl25149108.hc.cloud.uk.hsbc, gbl25183782.systems.uk.hsbc, gbl25185915.systems.uk.hsbc, the script should check the input parameter and determine which env it is, and execute the corresponding commands based on the env.

## 2.14, there is one input paramater for the script, which is the co-ops version number, for example, 4.4.3.3, the script should check the input parameter and determine which version it is, and execute the corresponding commands based on the version

## 2.15, there is one input parameter for the script, like --auto-continue, if this parameter is passed to the script, it will automatically continue to the next step without waiting for user input, and it will print the message "auto continue to the next step" to log file before continue to the next step.

## 2.16, the script should be able to run in linux environment, especially for RHEL8 x86-linux64, and it should be compatible with bash
