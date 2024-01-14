!*/bin/bash

set -e

MYSQL_PASSWORD=$1

PROJECT_DIR="/var/www/html/posts"

# make dir if not exists (first deploy)
mkdir -p $PROJECT_DIR

cd $PROJECT_DIR

git config --global --add safe.directory $PROJECT_DIR

# the project has not been cloned yet (first deploy)

if [ ! -d $PROJECT_DIR"/.git"]; then
  GIT_SSH_COMMAND='ssh -i /home/id_rsa -o IdentitiesOnly=yes' git clone git@github.com:simcha22/DevOpsFundamentals.git
else
  GIT_SSH_COMMAND='ssh -i /home/id_rsa -o IdentitiesOnly=yes' git pull
fi

cd $PROJECT_DIR"/frontend"
npm install
npm run build

cd $PROJECT_DIR"/api"

composer install --no-interaction --optimize-autoloader --no-dev

if [ ! -f $PROJECT_DIR"/api/.env" ]; then
  cp .env.example .env
  sed -i "/DB_PASSWORD/c\DB_PASSWORD=$MYSQL_PASSWORD" $PROJECT_DIR"/api/.env"
  sed -i '/QUEUE_CONNECTION/c\QUEUE_CONNECTION=database' $PROJECT_DIR"/api/.env"
  php artisan key:generate
fi

chown -R www-data:www-data $PROJECT_DIR

php artisan storage:link
php artisan optimize:clear

php artisan down

php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan up

sudo cp $PROJECT_DIR"/deployment/config/nginx.conf" /etc/nginx/nginx.conf
# test the config so if it's not valid we don't try to reload it
sudo nginx -t
sudo systemctl reload nginx

apt install supervisor -y

cp $PROJECT_DIR"/deployment/config/supervisord.conf" /etc/supervisor/conf.d/supervisord.conf
# update the config
supervisorctl update
# restart workers (notice the : at the end. it refers to the process group)
supervisorctl restart workers:

