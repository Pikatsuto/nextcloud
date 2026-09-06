# nextcloud

Nextcloud stack (Apache + PostgreSQL + Redis + Collabora + notify_push High
Performance Backend) running behind Traefik.

The `ghcr.io/<owner>/<repo>` image is rebuilt **once a month** by GitHub Actions
(`.github/workflows/build.yml`) to pick up updates of the
`nextcloud:production-apache` base. **Watchtower**, on the server, detects the
new digest and updates the container automatically.

## Files

| File | Role |
|---|---|
| `Dockerfile` | `nextcloud:production-apache` base + supervisor (apache + cron + notify_push) |
| `supervisord.conf` | Supervises the three processes. `notify_push` reads `NOTIFY_PUSH_PORT` and `NOTIFY_PUSH_DB_PREFIX` from the environment |
| `hooks/` | Nextcloud entrypoint hooks (install/enable `notify_push`) |
| `docker-compose.yml` | Deployment descriptor — no infra value hardcoded, everything via `${...}` |
| `.env` | **Real secrets + domains + hosts + paths — gitignored, never pushed** |
| `.env.example` | Template to copy to `.env` |

## Configuration (`.env`)

No infra-specific value (passwords, public domains, internal hostnames, server
paths) lives in the compose file or on GitHub: everything is in `.env`, which is
gitignored. To start from scratch:

```sh
cp .env.example .env   # then fill in the real values
```

## Deployment

```sh
docker compose pull        # fetch the latest GHCR image
docker compose up -d
```

> The GHCR image must be **public**: Watchtower has no registry credentials, so
> it can only pull a public image.
