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

#-------------------------------------------------------------------------------
# Generate the log file
#-------------------------------------------------------------------------------

LOG=~/app-server-setup-$(date '+%Y%m%d-%H%M%S').log

echo
comments "Your application server setup log is located at: $LOG"
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
# Install and configure Apache web server
#-------------------------------------------------------------------------------

starting 'Install and configure Apache web server'

apt install -y \
    apache2 \
    apache2-utils \
    >> $LOG 2>&1
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf >> $LOG 2>&1
sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/' /etc/apache2/sites-available/000-default.conf >> $LOG 2>&1
a2enmod rewrite >> $LOG 2>&1

finished 'Install and configure Apache web server'

#-------------------------------------------------------------------------------
# Install and configure PHP 7.4
#-------------------------------------------------------------------------------

starting 'Install and configure PHP 7.4'

apt install -y \
    php7.4 \
    libapache2-mod-php7.4 \
    php7.4-bcmath \
    php7.4-cli \
    php7.4-ctype \
    php7.4-curl \
    php7.4-fileinfo \
    php7.4-gd \
    php7.4-igbinary \
    php7.4-imagick \
    php7.4-imap \
    php7.4-intl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-memcached \
    php7.4-msgpack \
    php7.4-mysql \
    php7.4-pcov \
    php7.4-pdo \
    php7.4-pgsql \
    php7.4-readline \
    php7.4-redis \
    php7.4-soap \
    php7.4-tokenizer \
    php7.4-xdebug \
    php7.4-xml \
    php7.4-zip \
    >> $LOG 2>&1

finished 'Install and configure PHP 7.4'

#-------------------------------------------------------------------------------
# Install required application schedulers
#-------------------------------------------------------------------------------

starting 'Install required application schedulers'

apt install -y \
    cron \
    supervisor \
    >> $LOG 2>&1

finished 'Install required application schedulers'

#-------------------------------------------------------------------------------
# Install Composer package manager
#-------------------------------------------------------------------------------

starting 'Install Composer package manager'

curl -sS https://getcomposer.org/installer -o composer-setup.php >> $LOG 2>&1
php composer-setup.php --install-dir=/usr/local/bin --filename=composer >> $LOG 2>&1

finished 'Install Composer package manager'

#-------------------------------------------------------------------------------
# Install Node and package manager
#-------------------------------------------------------------------------------

starting 'Install Node and package manager'

curl -sL https://deb.nodesource.com/setup_16.x | bash - >> $LOG 2>&1
apt install -y nodejs >> $LOG 2>&1
npm install --location=global npm >> $LOG 2>&1
npm install --location=global npm >> $LOG 2>&1

finished 'Install Node and package manager'

#-------------------------------------------------------------------------------
# Ensure all services are running
#-------------------------------------------------------------------------------

starting 'Ensure all services are running'

service cron start >> $LOG 2>&1
service supervisor start >> $LOG 2>&1
service apache2 restart >> $LOG 2>&1

finished 'Ensure all services are running'

#-------------------------------------------------------------------------------
# Install the web application
#-------------------------------------------------------------------------------

starting 'Install the web application'

cd /var/www >> $LOG 2>&1
rm -rf html/ >> $LOG 2>&1
git config --global --add safe.directory /var/www >> $LOG 2>&1
git clone https://github.com/IngenuitySoftwareLabs/Service-Pros.git . >> $LOG 2>&1

finished 'Install the web application'

#-------------------------------------------------------------------------------
# Complete the server setup
#-------------------------------------------------------------------------------

sleep 1

echo
comments 'Your application server setup is complete'
echo
