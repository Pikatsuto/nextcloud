#!/bin/sh
# Runs ONCE after the first install.
# The domain comes from the global Docker environment variable
# NEXTCLOUD_TRUSTED_DOMAINS (already defined in the container).
set -eu

run_occ() {
   if [ "$(id -u)" = 0 ]; then
      su -s /bin/sh www-data -c "php /var/www/html/occ $1"
   else
      sh -c "php /var/www/html/occ $1"
   fi
}

echo "==> [hook] Installing the notify_push app"
run_occ "app:install notify_push" || run_occ "app:enable notify_push" || true

echo "==> [hook] Local APCu cache"
run_occ "config:system:set memcache.local --value='\\OC\\Memcache\\APCu'" || true

echo "==> [hook] Registering High Performance Backend URL"
run_occ "notify_push:setup https://${NEXTCLOUD_TRUSTED_DOMAINS}/push" || true

echo "==> [hook] post-installation done"
