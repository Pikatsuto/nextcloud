FROM nextcloud:production-apache

# Required when overriding the start command: without it the official
# entrypoint does not run the Nextcloud install/update step.
ENV NEXTCLOUD_UPDATE=1

# supervisord: runs apache2 + cron + notify_push in the same container
RUN apt-get update \
 && apt-get install -y --no-install-recommends supervisor \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/log/supervisord

COPY supervisord.conf /etc/supervisor/conf.d/nextcloud.conf

# Hooks run automatically by the official Nextcloud entrypoint
COPY hooks/post-installation/ /docker-entrypoint-hooks.d/post-installation/
COPY hooks/before-starting/   /docker-entrypoint-hooks.d/before-starting/
RUN chmod +x /docker-entrypoint-hooks.d/post-installation/*.sh \
             /docker-entrypoint-hooks.d/before-starting/*.sh

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
