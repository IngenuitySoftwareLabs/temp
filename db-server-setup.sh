#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

function comments {
    echo -e "\e[3;36m$1\e[0m"
}

function starting {
    echo -e -n "\e[33m[$(date '+%H:%M:%S')] $1 \e[35m(running)\e[0m"
}

function finished {
    echo -e "\r\e[K\e[32m[$(date '+%H:%M:%S')] $1\e[0m"
}

function skipping {
    echo -e "\r\e[K\e[2;32m[$(date '+%H:%M:%S')] $1 (skipped on localhost)\e[0m"
}

function stopping {
    echo -e "\e[3;31m$1\e[0m"
}

function input {
    if [ -n "$2" ]
    then
        read -p "$1 (ENTER for $2): " temp
        echo ${temp:-$2}
    else
        read -p "$1: " temp
        echo $temp
    fi
}

function config {
    echo -e "\e[32m$1\e[35m = \e[33m$2\e[0m"
}

#-------------------------------------------------------------------------------
# Collect the database environment values
#-------------------------------------------------------------------------------

echo
comments 'Please provide the following information:'
echo

DB_USERNAME=$(input 'Database Username' 'dbadmin')
DB_PASSWORD=$(input 'Database Password')
DB_DATABASE=$(input 'Database Name (eg: my_app)' 'defaultdb')
BIND_ADDRESS=$(input 'Bind to Address' 'localhost')

#-------------------------------------------------------------------------------
# Confirm the database environment values
#-------------------------------------------------------------------------------

sleep 1

echo
comments 'Please confirm the following values:'
echo

config 'Database Username' $DB_USERNAME
config 'Database Password' $DB_PASSWORD
config 'Database Name' $DB_DATABASE
config 'Bind to Address' $BIND_ADDRESS

sleep 1

echo
comments 'If everything looks correct, please confirm below'
echo

read -p 'Ready to proceed with the database server setup? (Y/N)' reply
echo

if [[ ! $reply =~ ^[Yy]$ ]]
then
    stopping 'Exiting the database server setup'
    echo

    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

sleep 1

#-------------------------------------------------------------------------------
# Generate the log file
#-------------------------------------------------------------------------------

LOG=~/db-server-setup-$(date '+%Y%m%d-%H%M%S').log

comments "Your database server setup log is located at: $LOG"
echo

sleep 1

#-------------------------------------------------------------------------------
# Update the Ubuntu Server apt repository
#-------------------------------------------------------------------------------

starting 'Update the Ubuntu Server apt repository'

apt update >> $LOG 2>&1
apt upgrade -y >> $LOG 2>&1

finished 'Update the Ubuntu Server apt repository'

#-------------------------------------------------------------------------------
# Install required system commands
#-------------------------------------------------------------------------------

starting 'Install required system commands'

apt install -y \
    htop \
    mytop \
    net-tools \
    curl \
    unzip \
    git \
    >> $LOG 2>&1

finished 'Install required system commands'

#-------------------------------------------------------------------------------
# Install and configure the MySQL database server
#-------------------------------------------------------------------------------

starting 'Install and configure the MySQL database server'

apt install -y mysql-server >> $LOG 2>&1
service mysql start >> $LOG 2>&1
mysql -e "DELETE FROM mysql.user WHERE User='';" >> $LOG 2>&1
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> $LOG 2>&1
mysql -e "DROP DATABASE IF EXISTS test;" >> $LOG 2>&1
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >> $LOG 2>&1
mysql -e "FLUSH PRIVILEGES;" >> $LOG 2>&1

finished 'Install and configure the MySQL database server'

#-------------------------------------------------------------------------------
# Create the MySQL user and database
#-------------------------------------------------------------------------------

starting 'Create the MySQL user and database'

mysql -e "CREATE DATABASE $DB_DATABASE;" >> $LOG 2>&1
mysql -e "CREATE USER '$DB_USERNAME'@'*' IDENTIFIED BY '$DB_PASSWORD';" >> $LOG 2>&1
mysql -e "GRANT ALL PRIVILEGES ON $DB_DATABASE.* TO '$DB_USERNAME'@'*';" >> $LOG 2>&1
mysql -e "FLUSH PRIVILEGES;" >> $LOG 2>&1

finished 'Create the MySQL user and database'

#-------------------------------------------------------------------------------
# Configure MySQL for remote connections
#-------------------------------------------------------------------------------

starting 'Configure MySQL for remote connections'

if [ $BIND_ADDRESS = 'localhost' ]
then
    skipping 'Configure MySQL for remote connections'
else
    sed -i "s/bind-address\t\t= 127.0.0.1/bind-address\t\t= $BIND_ADDRESS/" /etc/mysql/mysql.conf.d/mysqld.cnf >> $LOG 2>&1
    service mysql restart >> $LOG 2>&1

    finished 'Configure MySQL for remote connections'
fi

#-------------------------------------------------------------------------------
# Complete the server setup
#-------------------------------------------------------------------------------

sleep 1

echo
comments 'Your database server setup is complete'
echo
