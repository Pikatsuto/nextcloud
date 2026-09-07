#!/bin/sh
# Runs on EVERY start (idempotent). Wires the ONLYOFFICE connector (OOXML
# editor) to this stack's Document Server. Collabora keeps ODF. Host and JWT
# come from the environment -> no value hardcoded.
set -eu

run_occ() {
   if [ "$(id -u)" = 0 ]; then
      su -s /bin/sh www-data -c "php /var/www/html/occ $1"
   else
      sh -c "php /var/www/html/occ $1"
   fi
}

# Do nothing until Nextcloud is installed
if [ ! -f /var/www/html/config/config.php ]; then
   echo "==> [hook] Nextcloud not installed yet, skipping onlyoffice"
   exit 0
fi

# Need the Document Server host + JWT secret
if [ -z "${ONLYOFFICE_DOMAIN:-}" ] || [ -z "${ONLYOFFICE_JWT_SECRET:-}" ]; then
   echo "==> [hook] ONLYOFFICE_DOMAIN/JWT unset, skipping onlyoffice"
   exit 0
fi

run_occ "app:install onlyoffice" 2>/dev/null || run_occ "app:enable onlyoffice" 2>/dev/null || true

# Public URL: the browser loads the editor from here.
run_occ "config:app:set onlyoffice DocumentServerUrl --value=https://${ONLYOFFICE_DOMAIN}/"
# Internal URL: Nextcloud <-> Document Server on the same docker network,
# bypassing the edge proxy (Cloudflare).
run_occ "config:app:set onlyoffice DocumentServerInternalUrl --value=http://cn-nextcloud-onlyoffice/"
# Shared JWT secret (must match the Document Server's JWT_SECRET).
run_occ "config:app:set onlyoffice jwt_secret --value=${ONLYOFFICE_JWT_SECRET}"
run_occ "config:app:set onlyoffice jwt_header --value=Authorization"

# Format split (OnlyOffice = OOXML, Collabora = ODF) is finalized via the
# OnlyOffice admin "editable formats" settings after first deploy, since the
# exact keys are version-specific; see README.

echo "==> [hook] onlyoffice wired to https://${ONLYOFFICE_DOMAIN}"
