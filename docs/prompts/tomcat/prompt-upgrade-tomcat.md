prompt

As one linux and tomcat export, please develop one script to automate tomcat 9.0.116, used by abinitio, upgrade process

# Tomcat Upgrade processs 
The tomcat 9 upgrade process is as below

## Step 1 Verify the tomcat 9.0.116 installation file existence

for ienv : verify file existence under path /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz
for denv : verify file existence under path /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz
for benv : verify file existence under path /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz
for penv : verify file existence under path /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz
for penv-cont : verify file existence under path /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz

## Step 2 Back up existing tomcat 9 directories

### 2.1 back up three existing tomcat 9 existing directories

for ienv:

cp -R /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
cp -R /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
cp -R /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for denv:

cp -R /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
cp -R /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
cp -R /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for benv:

cp -R /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
cp -R /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
cp -R /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for penv:

cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>


for penv-cont:

cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

DDMMYYYY is the date when you do the upgrade, for example, if you do the upgrade on 20th June 2024, the DDMMYYYY should be 20062024

### 2.2 archive the files

for ienv:

tar -czf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for denv:

tar -czf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for benv:

tar -czf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for penv:

tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>

for penv-cont:

tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>
tar -czf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>



## Step 3 Stop web app service

for ienv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.ienv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh stop application

for denv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.denv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/denv.abinitio.runner.sh stop application

for benv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.benv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/benv.abinitio.runner.sh stop application

for penv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.penv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/penv.abinitio.runner.sh stop application

for penv-cont :

it does not need to stop the application

## Step 4 Rename three tomcat 9 directories

for ienv:
mv /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org
mv /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org
mv /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org

for denv:
mv /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org
mv /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org
mv /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org

for benv:
mv /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org
mv /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org
mv /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org

for penv:
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org

for penv-cont:
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org
mv /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0 /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org


## Step 5 Install tomcat 9.0.116

for ienv:
source /FCR_APP/abinitio/management/scripts/ab.profile.ienv-V4-3-1-6
cd /FCR_APP/abinitio/ienv/abinitio-app-hub/apps
ab-app install /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz

for denv:
source /FCR_APP/abinitio/management/scripts/ab.profile.denv-V4-3-1-6
cd /FCR_APP/abinitio/denv/abinitio-app-hub/apps
ab-app install /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz

for benv:
source /FCR_APP/abinitio/management/scripts/ab.profile.benv-V4-3-1-6
cd /FCR_APP/abinitio/benv/abinitio-app-hub/apps
ab-app install /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz

for penv:
source /FCR_APP/abinitio/management/scripts/ab.profile.penv-V4-3-1-6
cd /FCR_APP/abinitio/penv/abinitio-app-hub/apps
ab-app install /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz


for penv-cont:
source /FCR_APP/abinitio/management/scripts/ab.profile.penv-V4-3-1-6
cd /FCR_APP/abinitio/penv/abinitio-app-hub/apps
ab-app install /FCR_APP/abinitio/software/Tomcat/9.0.116/apache-tomcat-9.0.116.tar.gz


## Step 6 Verify tomcat 9.0.116 installation

### 6.1 check the version , the output should contain 9.0.116

for ienv:
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0/bin/version.sh

for denv:
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0/bin/version.sh

for benv:
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0/bin/version.sh

for penv:
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/version.sh

for penv-cont:
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/version.sh

### 6.2 verify the three newly created directory

after installation, there should be three directories created under path abinitio-app-hub/apps with name catalina-home-9.0 , catalina-base-9.0-tmplt and catalina-base-9.0

for ienv:

/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0

for denv:

/FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0

for benv:

/FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0

for penv:

/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0


for penv-cont:

/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0

if the direcroty doesn't exist, please stop and throw error 

## Step 7 Restore some old files from catalina-home-9.0_org directory

### 7.1 restore catalina.bat and catalina.sh files under catalina-home-9.0 directory

for ienv:

check the difference with follwoing command

diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org/bin

if there's any difference , please restore the objects from path catalina-home-9.0_org

cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.bat /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.bat
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.sh /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.sh

after that, pls run diff command again to ensure there's no difference

for denv:

check the difference with follwoing command

diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org/bin

if there's any difference , please restore the objects from path catalina-home-9.0_org

cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.bat /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.bat
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.sh /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.sh

after that, pls run diff command again to ensure there's no difference

for benv:

check the difference with follwoing command

diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org/bin

if there's any difference , please restore the objects from path catalina-home-9.0_org

cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.bat /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.bat
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.sh /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.sh

after that, pls run diff command again to ensure there's no difference

for penv:

check the difference with follwoing command

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin

if there's any difference , please restore the objects from path catalina-home-9.0_org

cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.bat /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.bat
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.sh /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.sh

after that, pls run diff command again to ensure there's no difference

for penv-cont:

check the difference with follwoing command

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin

if there's any difference , please restore the objects from path catalina-home-9.0_org

cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.bat /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.bat
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin/catalina.sh /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin/catalina.sh

after that, pls run diff command again to ensure there's no difference

## Step 8 Restore some old files from catalina-base-9.0_org directory

under path catalina-base-9.0 path, run ls command to list all directories , in each directory, run diff command to check the difference between new and old (_org) directory, if there's any difference, please restore the objects from path catalina-base-9.0_org

for example, if there are following directories under catalina-base-9.0 directory

conf
logs
temp
webapps
work

### 8.1 in conf directory, restore files logging.properties, web.xml and server.xml from catalina-base-9.0_org directory

for ienv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0_org

cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/logging.properties /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/conf/logging.properties
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/web.xml /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/conf/web.xml
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/server.xml /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for denv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0_org

cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/logging.properties /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/conf/logging.properties
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/web.xml /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/conf/web.xml
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/server.xml /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for benv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0_org

cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/logging.properties /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/conf/logging.properties
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/web.xml /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/conf/web.xml
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/server.xml /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for penv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0_org

cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/logging.properties /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/logging.properties
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/web.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/web.xml
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/server.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for penv-cont :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0_org

cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/logging.properties /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/logging.properties
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/web.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/web.xml
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf/server.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf/server.xml

after that, pls run diff command again to ensure there's no difference

### 8.2 in logs directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0_org, but if there's no difference, pls ignore it

### 8.3 in temp directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0_org, but if there's no difference, pls ignore it

### 8.4 in webapps directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0_org

for example,

for ienv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps/* /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/webapps/

after that, pls run diff command again to ensure there's no difference.

for denv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps/* /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/webapps/

after that, pls run diff command again to ensure there's no difference

for benv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps/* /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/webapps/

after that, pls run diff command again to ensure there's no difference

for penv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps/* /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps/

after that, pls run diff command again to ensure there's no difference

for penv-cont:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps/* /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps/

after that, pls run diff command again to ensure there's no difference

### 8.5 in work directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0_org, but if there's no difference, pls ignore it

## Step 9 Restore some old files from catalina-base-9.0-tmplt_org directory

under path catalina-base-9.0-tmplt path, run ls command to list all directories , in each directory, run diff command to check the difference between new and old (_org) directory

for example, if there are following directories under catalina-base-9.0-tmplt directory

conf
logs
temp
webapps
work



### 9.1 in conf directory, restore files logging.properties, web.xml and server.xml and Catalina directroy from catalina-base-9.0-tmplt_org directory

for ienv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

cp -R /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/Catalina /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/Catalina
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/logging.properties /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/logging.properties
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/web.xml /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/web.xml
cp -p /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/server.xml /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for denv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

cp -R /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/Catalina /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/Catalina
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/logging.properties /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/logging.properties
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/web.xml /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/web.xml
cp -p /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/server.xml /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for benv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

cp -R /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/Catalina /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/Catalina
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/logging.properties /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/logging.properties
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/web.xml /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/web.xml
cp -p /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/server.xml /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for penv :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

cp -R /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/Catalina /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/Catalina
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/logging.properties /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/logging.properties
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/web.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/web.xml
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/server.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/server.xml

after that, pls run diff command again to ensure there's no difference

for penv-cont :
run diff command to check difference between new and old (_org) directory

diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/logging.properties /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/logging.properties
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/web.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/web.xml
cp -p /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf/server.xml /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf/server.xml

after that, pls run diff command again to ensure there's no difference

### 9.2 in logs directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org, but if there's no difference, ignore it

### 9.3 in temp directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org, but if there's no difference, ignore it

### 9.4 in webapps directory, pls run diff command to check the difference between new and old (_org) directory

if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

for example,

for ienv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps/* /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps/

after that, pls run diff command again to ensure there's no difference

for denv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps/* /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps/

after that, pls run diff command again to ensure there's no difference

for benv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps/* /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps/

after that, pls run diff command again to ensure there's no difference

for penv:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps/* /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps/

after that, pls run diff command again to ensure there's no difference

for penv-cont:
run diff command to check the difference between new and old (_org) directory
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps

if there are some differences for some webapps, we can restore it from _org directory

cp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps/* /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps/

after that, pls run diff command again to ensure there's no difference

### 9.5 in work directory, pls run diff command to check the difference between new and old (_org) directory, if there's any difference, please restore the objects from path catalina-base-9.0-tmplt_org

but if there's no difference, pls ignore the difference and do not restore the objects from path catalina-base-9.0-tmplt_org, because these directories are used to store the work files, we don't need to restore the old work files to new tomcat 9.0.116 version

## Step 10 compare the new and old three tomcat base directories, make sure there's no difference

### Step 10.1 compare the catalina-home-9.0 directory with catalina-home-9.0_org directory

compare the two directories with following command

for ienv:
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org/bin
the output should be empty, if there's any difference

for denv:
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org/bin
the output should be empty, if there's any difference

for benv:
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org/bin
the output should be empty, if there's any difference

for penv:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin
the output should be empty, if there's any difference

for penv-cont:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0/bin /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org/bin
the output should be empty, if there's any difference

### Step 10.2 compare the catalina-base-9.0 directory with catalina-base-9.0_org directory

compare the two directories with following command

for ienv:
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/logs /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/logs
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/temp
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0/work /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org/work
the output should be empty

for denv:
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/logs /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/logs
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/temp
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0/work /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org/work
the output should be empty

for benv:
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/logs /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/logs
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/temp
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0/work /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org/work
the output should be empty

for penv:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/logs /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/logs
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/temp
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/work /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/work
the output should be empty

for penv-cont:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/conf
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/logs /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/logs
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/temp
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/webapps
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0/work /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org/work
the output should be empty


### Step 10.3 compare the catalina-base-9.0-tmplt directory with catalina-base-9.0-tmplt_org directory

compare the two directories with following command

for ienv:
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/logs /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/logs
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/temp
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps
diff /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/work /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/work
the output should be empty

for denv:
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/logs /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/logs
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/temp
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps
diff /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/work /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/work
the output should be empty

for benv:
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/logs /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/logs
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/temp
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps
diff /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/work /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/work
the output should be empty

for penv:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/logs /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/logs
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/temp
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/work /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/work
the output should be empty

for penv-cont:
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/conf
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/logs /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/logs
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/temp
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/webapps
diff /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt/work /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org/work
the output should be empty

## Step 11 Start web apps

### Step 11.1 purge the working files for all web apps

for ienv:

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/logs
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/agienv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/logs
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/logs
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/ccienvnext/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/logs
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/eiienv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/conf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/logs
/FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/temp /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/webapps /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/mhdrienv/work

for denv:

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/logs
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/agdenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/logs
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/ccdenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/logs
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/eidenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/conf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/logs
/FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/temp /FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/webapps /FCR_APP/abinitio/denv/abinitio-app-hub/apps/mhdrdenv/work

for benv:

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/logs
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/agbenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/logs
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/ccbenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/logs
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/amlccbenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/conf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/logs
/FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/temp /FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/webapps /FCR_APP/abinitio/benv/abinitio-app-hub/apps/mhdrbenv/work

for penv:

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/work

for penv-cont:

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/agpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/ccpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/amlccpenv/work

delete conf/ logs/ temp/ webapps/ work/ under path /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/conf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/logs
/FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/temp /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/webapps /FCR_APP/abinitio/penv/abinitio-app-hub/apps/mhdrpenv/work


### Step 11.2 start all web apps

for ienv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.ienv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh start application

for denv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.denv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/denv.abinitio.runner.sh start application

for benv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.benv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/benv.abinitio.runner.sh start application

for penv :

cd /FCR_APP/abinitio/tmp
source /FCR_APP/abinitio/management/scripts/ab.profile.penv-V4-3-1-6
/FCR_APP/abinitio/management/scripts/penv.abinitio.runner.sh start application


for penv-cont :
it doesn't need to start the application for penv-cont env

## Step 13 Remove tomcat 9 _org directories

for ienv:
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_org
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_org
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org

for denv:
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_org
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_org
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org

for benv:
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_org
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_org
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org

for penv:
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_org
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_org
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_org

## Step 14 Remove the archive files 

for ienv:
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/ienv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz 

for denv:
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/denv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz 

for benv:
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/benv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz 

for penv:
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-home-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0_<DDMMYYYY>.tar.gz 
rm -rf /FCR_APP/abinitio/penv/abinitio-app-hub/apps/catalina-base-9.0-tmplt_<DDMMYYYY>.tar.gz 

# Requirement Detail of the script 

## 2.1 define one script and respective configuration files based on different envs, so that it's easy to change the setting in configuration files, no need to update script, when calling the script, we can specify the config file location 

## 2.2 it support dry-run mode (only print out commands) and debug mode

## 2.3 print commands before executing the commands in each step

## 2.4 all outputs should be logged to log file, and the log file should be rotated by date, for example, catalina-base-9.0-tmplt_update_20240624.log, and logs should be put into certain directory, it can delete the logs which are older than 90 days to save the disk space automatically

## 2.5 if there's any error in any step, the script should stop and print the error message to log file

## 2.6 the script should be idempotent, which means if we run the script multiple times, it should not cause any issue, and the result should be the same as running the script once

## 2.7 add more comments in script

## 2.8 add emoji when printing the log message

## 2.9 it can support to start the script from a specified step, for example, if we want to start the script from step 9, we can pass the parameter "step_9" to the script, and the script will start from step 9, and execute the following steps

## 2.10, in my example, i use 9.0.116 as example, it should also support to update to other versions, for example, 9.0.117, we can pass the parameter "9.0.117" to the script, and the script will update to 9.0.117 version

## 2.11. try to parameterize the script as much as possible, like the path etc, later, we may conduct the testing in my local virtual machine later
