!*/bin/bash
set -e

MYSQL_PASSWORD=$1
SSH_KEY=$2

PROJECT_DIR="/var/www/html/posts"

mkdir -p $PROJECT_DIR

chown -R www-data:www-data $PROJECT_DIR

cd $PROJECT_DIR

if [ ! -d $PROJECT_DIR"/.git" ]; then
  GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes' git clone git@github.com:simcha22/DevOpsFundamentals.git .
  cp $PROJECT_DIR"/api/.env.example" $PROJECT_DIR"/api/.env"
  sed -i "/DB_PASSWORD/c\DB_PASSWORD=$MYSQL_PASSWORD" $PROJECT_DIR"/api/.env"
  sed -i '/QUEUE_CONNECTION/c\QUEUE_CONNECTION=database' $PROJECT_DIR"/api/.env"
fi

# node & npm
rm -f /usr/bin/node
rm -f /usr/bin/npm
rm -f /usr/bin/npx

cd /usr/lib
wget https://nodejs.org/dist/v20.10.0/node-v20.10.0-linux-x64.tar.xz
tar xf node-v20.10.0-linux-x64.tar.xz
rm node-v20.10.0-linux-x64.tar.xz
mv ./node-v20.10.0-linux-x64/bin/node /usr/bin/node
ln -s /usr/lib/node-v20.10.0-linux-x64/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm
ln -s /usr/lib/node-v20.10.0-linux-x64/lib/node_modules/npx/bin/npx-cli.js /usr/bin/npx


add-apt-repository ppa:ondrej/php -y

apt update -y
apt install php8.1-common php8.1-cli -y apt install php8.1-dom -y
apt install php8.1-gd -y
apt install php8.1-zip -y
apt install php8.1-curl -y
apt install php8.1-mysql -y
apt install php8.1-sqlite3 -y
apt install php8.1-mbstring -y
apt install php8.1-fpm -y

apt install net-tools -y
apt install supervisor -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/bin/composer


mysql -uroot -p$MYSQL_PASSWORD < $PROJECT_DIR"/deployment/config/mysql/create_database.sql" || echo "Database already exists"
mysql -uroot -p$MYSQL_PASSWORD < $PROJECT_DIR"/deployment/config/mysql/set_native_password.sql"

echo "* * * * * cd $PROJECT_DIR && php artisan schedule:run >> /dev/null 2>&1" >> cron_tmp
crontab cron_tmp
rm cron_tmp

cp $PROJECT_DIR"/deployment/config/supervisor/logrotate" /etc/logrotate.d/supervisor

useradd -G www-data,root -u 1000 -d /home/simcha simcha
mkdir -p /home/simcha/.ssh
touch /home/simcha/.ssh/authorized_keys
chown -R simcha:simcha /home/simcha
chown -R simcha:simcha /var/www/html
chmod 700 /home/simcha/.ssh
chmod 644 /home/simcha/.ssh/authorized_keys

echo "$SSH_KEY" >> /home/simcha/.ssh/authorized_keys

echo "simcha ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/simcha

php -v
node -v
npm -v