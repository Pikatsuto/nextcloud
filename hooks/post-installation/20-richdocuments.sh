#!/bin/sh
# Runs ONCE after the first install. Installs and connects the built-in
# Nextcloud Office (richdocuments) connector to this stack's Collabora, so a
# brand-new deploy is functional on first boot. The before-starting hook then
# keeps it in sync on every later start. Collabora host comes from the
# environment (COLLABORA_DOMAIN) -> no value hardcoded.
set -eu

run_occ() {
   if [ "$(id -u)" = 0 ]; then
      su -s /bin/sh www-data -c "php /var/www/html/occ $1"
   else
      sh -c "php /var/www/html/occ $1"
   fi
}

if [ -z "${COLLABORA_DOMAIN:-}" ]; then
   echo "==> [hook] COLLABORA_DOMAIN unset, skipping richdocuments"
   exit 0
fi

WOPI_URL="https://${COLLABORA_DOMAIN}"

run_occ "app:install richdocuments" || run_occ "app:enable richdocuments" || true
run_occ "config:app:set richdocuments wopi_url --value=${WOPI_URL}"
run_occ "config:app:set richdocuments public_wopi_url --value=${WOPI_URL}"
if [ -n "${WOPI_ALLOWLIST:-}" ]; then
   run_occ "config:app:set richdocuments wopi_allowlist --value=${WOPI_ALLOWLIST}"
fi
   # Collabora handles ODF, not OOXML (OnlyOffice does OOXML) -> default new docs to ODF
   run_occ "config:app:set richdocuments doc_format --value=odf"
run_occ "richdocuments:activate-config" || true

echo "==> [hook] richdocuments wired to ${WOPI_URL}"
