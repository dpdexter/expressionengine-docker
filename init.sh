#! /bin/bash
# Preflight Checks
ECHO "[0] Preflight checks:"
if ! [ -x "$(command -v docker)" ]; then
    printf "Docker is not installed, exiting\\n"
    exit 1
fi
ECHO "    - Docker is installed." 
if ! [ -x "$(command -v docker-compose)" ]; then
    printf "Docker Compose is not installed, exiting\\n"
    exit 1
fi 
ECHO "    - Docker Compose is installed." 

# Set the version of EE 
read -p "Enter the version of ExpressionEngine or return for default [5.3.0]: " ee_version
EE_VERSION=${ee_version:-"5.3.0"}
ECHO  "[1] Gathering Settings:"

read -p "Enter a project slug name. lowercase charaters only. [mysite]: " mysite
MYSITE=${mysite:-mysite}

# Create a MySQL password
read -p "Enter your desired mysql password [random generated string]: " mypassword
MYSQL_PASSWORD=${mypassword:-$(env LC_CTYPE=C tr -dc "a-zA-Z0-9" < /dev/urandom | head -c 24)}

ECHO "    - Setting ExpressionEngine Version To $EE_VERSION"
ECHO "    - Setting MySite slug to $EE_VERSION"
ECHO "    - Setting MySQL Password to $MYSQL_PASSWORD"

mkdir downloads && chmod -R 777 downloads
cd downloads

# Get EE From Github
ECHO "[2] Fetching ExpressionEngine Version from Github"
curl -LJOs  https://github.com/ExpressionEngine/ExpressionEngine/archive/$EE_VERSION.zip

ECHO "[3] Unzipping ExpressionEngine Download"
unzip -qq ExpressionEngine-$EE_VERSION.zip

# Make directories
ECHO "[4] Creating Directory Structure and moving files"
mkdir ../public
mkdir ../public/admin
mv ExpressionEngine-$EE_VERSION/images ../public/images
mv ExpressionEngine-$EE_VERSION/themes ../public/themes
mv ExpressionEngine-$EE_VERSION/index.php ../public/index.php
mv ExpressionEngine-$EE_VERSION/admin.php ../public/admin/index.php
mv ExpressionEngine-$EE_VERSION/system ../system
touch ../system/user/config/config.php

#move int the root location and set proper file permissions
ECHO "[5] Setting ExpressionEngine File Permissions"
cd ../
chmod -R 777 system/ee/ system/user/cache/ system/user/templates/ public/images/avatars/ public/images/captchas/ public/images/pm_attachments/ public/images/signature_attachments/ public/images/uploads/ public/themes/ee/ public/themes/user/

# Update the admin / index system path settings
ECHO "[6] Updating index and admin system_path settings"
sed -i '' -e 's/.\/system/..\/system/g' public/index.php 
sed -i '' -e 's/.\/system/..\/..\/system/g' public/admin/index.php 

# Update the build script
ECHO "[7] Updating the docker build scripts"
cp build/docker-compose.example build/docker-compose.yml
sed -i '' -e "s/\[SITENAME\]/$MYSITE/g" build/docker-compose.yml
sed -i '' -e "s/\[MYSQL_PASSWORD\]/$MYSQL_PASSWORD/g" build/docker-compose.yml

# Clean up
ECHO "[8] Clean up downloads folder"
rm -rf downloads

# fire up docker
ECHO "[9] Docker compose up"
cd build
docker-compose up -d

# create the default database
ECHO "[10] Creating your database"
mysql -u $MYSITE -p$MYSITE -P 3307 -h 127.0.0.1 $MYSITE -e "create database $MYSITE;" >> /dev/null 2>&1

# create the db dump / startup scripts
ECHO "[11] Creating your database backup and startup scripts"
mkdir ../data
mkdir ../data/db 
chmod -R 777 ../data
cp startup.example ../data/startup.sh
cp dbdump.example ../data/dbdump.sh
chmod +x ../data/startup.sh ../data/dbdump.sh 
sed -i '' -e "s/\[SITENAME\]/$MYSITE/g" ../data/startup.sh ../data/dbdump.sh 
sed -i '' -e "s/\[MYSQL_PASSWORD\]/$MYSQL_PASSWORD/g" ../data/startup.sh ../data/dbdump.sh
ECHO "    - MySQL startup file created in data/startup.sh"
ECHO "    - MySQL dump file created in data/dbdump.sh"

# lets get going!
ECHO "[12] All done. Here's what you need to proceed."
ECHO "Settings:"
ECHO "     - Control Panel: http://127.0.0.1/admin"
ECHO "     - [IMPORTANT] MySQL Host: $MYSITE-mysql"
ECHO "     - MySQL Database: $MYSITE"
ECHO "     - MySQL Username: $MYSITE"
ECHO "     - MySQL Password: $MYSQL_PASSWORD"
