# Multica Railway Template

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/multica?referralCode=YqmMB-&utm_medium=integration&utm_source=template&utm_campaign=generic)

Railway template for [Multica](https://github.com/multica-ai/multica), the open-source platform for running AI agents as teammates on infrastructure you control. It deploys:

- `frontend`: the Multica web app, from the upstream image `ghcr.io/multica-ai/multica-web:v0.4.41`
- `backend`: the Multica API, realtime hub, and daemon hub, from `ghcr.io/multica-ai/multica-backend:v0.4.41`, with a volume for uploads
- `pgvector`: PostgreSQL 17 with pgvector, on a volume

This repo holds only what Railway needs: two one-line Dockerfiles over the upstream images plus docs. Multica itself is not vendored here. Product docs, the CLI reference, and the self-hosting guide live upstream at https://multica.ai/docs/self-host-quickstart.

## First login

1. Open the `frontend` service's public domain and enter your email.
2. No email provider is configured by default, so the backend prints the code to its log:

   ```
   railway logs --service backend --filter "Verification code"
   ```

   or Railway dashboard, `backend` service, Logs. Enter the code.
3. To email codes instead, set `RESEND_API_KEY` and `RESEND_FROM_EMAIL` on `backend`, or the `SMTP_*` variables documented upstream. Leave them empty otherwise: a placeholder value such as a space is treated as a real key and every login fails with "failed to send verification code".

Once you have signed up, lock the instance down with `ALLOW_SIGNUP=false`, or restrict signups with `ALLOWED_EMAILS` / `ALLOWED_EMAIL_DOMAINS` (comma-separated).

## Connect a runtime

Agents execute on your machines through the Multica CLI daemon. The web app's runtime setup page shows the exact command; it is:

```
brew install multica-ai/tap/multica
multica setup self-host --server-url https://<backend-domain> --app-url https://<frontend-domain>
multica daemon status
```

The daemon connects to the `backend` public domain, not the frontend. That is why `backend` has a public domain and why the template sets `MULTICA_DAEMON_SERVER_URL` to it.

## Realtime and the two domains

The browser talks only to `frontend`. The web image proxies `/api`, `/auth`, `/uploads`, `/v1`, `/health`, and the `/ws` WebSocket upgrade to the backend over Railway's private network, so live updates (boards, agent activity) work on the default `*.up.railway.app` domains. Verified on v0.4.41: an issue created through the API arrives as an event on a WebSocket opened through the frontend domain.

Two optional variables ship empty for setups where the browser should reach the backend host directly instead, for example the frontend and backend on subdomains of one domain you own (`app.example.com`, `api.example.com`):

- `NEXT_PUBLIC_WS_URL` on `frontend`: `wss://api.example.com/ws`.
- `COOKIE_DOMAIN` on `backend`: `.example.com`, the narrowest parent domain covering both hosts. Required as soon as the browser reaches the API host directly. Without it the session cookie set on the frontend host is not sent along and writes fail with 403 CSRF errors. Every host under that domain receives the cookie, so only use it on a domain you fully control.

Leave both empty on the default domains.

## How it fits together

- `REMOTE_API_URL=http://backend.railway.internal:8080` is where the frontend proxies to. Cookies stay on one origin, so the backend's `CORS_ALLOWED_ORIGINS` is only a safety net.
- `DOCS_URL=https://multica.ai` is where the frontend sends `/docs` requests. It is read at runtime, so changing it needs no rebuild.
- `backend` reads `DATABASE_URL` from `${{pgvector.*}}` references. `JWT_SECRET`, `REALTIME_METRICS_TOKEN`, and `POSTGRES_PASSWORD` are generated per deploy.
- `LOCAL_UPLOAD_DIR=/app/data/uploads` is the backend volume; `LOCAL_UPLOAD_BASE_URL` is the backend's public domain so attachment links resolve.
- `ANALYTICS_DISABLED=true` turns off upstream telemetry.
- Migrations run inside the backend container on every start (`migrate up`, forward-only). The `/readyz` healthcheck only passes once the database and migration state are both `ok`, so a failed migration keeps the previous deployment serving.

## Upgrading Multica

Bump the tag in both `Dockerfile` and `Dockerfile.web` to the same upstream release (https://github.com/multica-ai/multica/releases). Merging to `main` notifies everyone who deployed the template. Migrations are forward-only, so record anything a deployer must know in `CHANGELOG.md` and tell them to back up `pgvector` first.

## Files

- `Dockerfile`: `backend` image
- `Dockerfile.web`: `frontend` image, selected on that service by `RAILWAY_DOCKERFILE_PATH=Dockerfile.web`
- `TEMPLATE_OVERVIEW.md`: the marketplace description
- `CHANGELOG.md`: what changed and how to upgrade an existing deployment

Template id `multica` in Railway's marketplace. Maintainers: the reference project that backs the template is `Multica` in the Railway workspace; the template definition is edited in the dashboard, then republished with `railway templates publish multica --readme-file TEMPLATE_OVERVIEW.md`.
