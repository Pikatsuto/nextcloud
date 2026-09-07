#!/bin/sh
# Runs ONCE after the first install. Installs and connects the ONLYOFFICE
# connector (OOXML editor) to this stack's Document Server, so a brand-new
# deploy is functional on first boot. The before-starting hook keeps it in
# sync afterwards. Host and JWT come from the environment -> no value hardcoded.
set -eu

run_occ() {
   if [ "$(id -u)" = 0 ]; then
      su -s /bin/sh www-data -c "php /var/www/html/occ $1"
   else
      sh -c "php /var/www/html/occ $1"
   fi
}

if [ -z "${ONLYOFFICE_DOMAIN:-}" ] || [ -z "${ONLYOFFICE_JWT_SECRET:-}" ]; then
   echo "==> [hook] ONLYOFFICE_DOMAIN/JWT unset, skipping onlyoffice"
   exit 0
fi

run_occ "app:install onlyoffice" || run_occ "app:enable onlyoffice" || true
run_occ "config:app:set onlyoffice DocumentServerUrl --value=https://${ONLYOFFICE_DOMAIN}/"
run_occ "config:app:set onlyoffice DocumentServerInternalUrl --value=http://cn-nextcloud-onlyoffice/"
run_occ "config:app:set onlyoffice jwt_secret --value=${ONLYOFFICE_JWT_SECRET}"
run_occ "config:app:set onlyoffice jwt_header --value=Authorization"

echo "==> [hook] onlyoffice wired to https://${ONLYOFFICE_DOMAIN}"
