#!/bin/sh
# Runs on EVERY start (idempotent). Ensures the notify_push app stays
# enabled even after an update or a restore.
set -eu

run_occ() {
   if [ "$(id -u)" = 0 ]; then
      su -s /bin/sh www-data -c "php /var/www/html/occ $1"
   else
      sh -c "php /var/www/html/occ $1"
   fi
}

# Do nothing until Nextcloud is installed (no config.php yet)
if [ ! -f /var/www/html/config/config.php ]; then
   echo "==> [hook] Nextcloud not installed yet, skipping notify_push"
   exit 0
fi

# Make sure the app is present and enabled (no-op if already so)
run_occ "app:install notify_push" 2>/dev/null || run_occ "app:enable notify_push" 2>/dev/null || true

echo "==> [hook] before-starting notify_push OK"
