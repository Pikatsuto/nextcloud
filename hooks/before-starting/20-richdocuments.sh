#!/bin/sh
# Runs on EVERY start (idempotent). Wires the built-in Nextcloud Office
# (richdocuments) connector to this stack's Collabora server, so a fresh
# deploy is functional out of the box. The Collabora host comes from the
# environment (COLLABORA_DOMAIN) -> no value hardcoded.
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
   echo "==> [hook] Nextcloud not installed yet, skipping richdocuments"
   exit 0
fi

# Need the Collabora host to connect to
if [ -z "${COLLABORA_DOMAIN:-}" ]; then
   echo "==> [hook] COLLABORA_DOMAIN unset, skipping richdocuments"
   exit 0
fi

WOPI_URL="https://${COLLABORA_DOMAIN}"

# App present and enabled (no-op if already so)
run_occ "app:install richdocuments" 2>/dev/null || run_occ "app:enable richdocuments" 2>/dev/null || true

# Point the connector at this stack's Collabora (browser + discovery)
run_occ "config:app:set richdocuments wopi_url --value=${WOPI_URL}"
run_occ "config:app:set richdocuments public_wopi_url --value=${WOPI_URL}"

# Optional extra lock: restrict which hosts may call Nextcloud's WOPI
# endpoints (leave WOPI_ALLOWLIST unset to rely on WOPI tokens only).
if [ -n "${WOPI_ALLOWLIST:-}" ]; then
   run_occ "config:app:set richdocuments wopi_allowlist --value=${WOPI_ALLOWLIST}"
fi

# Fetch discovery and apply
   # Collabora handles ODF, not OOXML (OnlyOffice does OOXML) -> default new docs to ODF
   run_occ "config:app:set richdocuments doc_format --value=odf"
run_occ "richdocuments:activate-config" || true

echo "==> [hook] richdocuments wired to ${WOPI_URL}"
