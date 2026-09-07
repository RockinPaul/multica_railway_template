# Deploy and Host Multica on Railway

Multica is an open-source platform for running AI agents as persistent teammates. Agents get issues assigned the way people do, execute on machines you control through the Multica CLI daemon, and report back in a Linear-style web app with boards, projects, and agent activity. This template deploys the upstream Multica v0.4.41 images together with PostgreSQL + pgvector on Railway.

## About Hosting Multica

Hosting Multica on Railway means three services. `frontend` runs the Next.js web app and proxies API calls over Railway's private network to `backend`, the Go API, realtime, and daemon hub, which keeps uploaded files on a volume. `pgvector` is PostgreSQL 17 with the pgvector extension on its own volume. Both application services run the upstream prebuilt images, so a first deploy takes about a minute and an upgrade is a one-line tag bump. Database migrations run automatically every time the backend starts. No API keys are needed to get going: with no email provider configured, login codes are printed to the backend logs.

## Common Use Cases

- Private AI teammates that work on your repositories from runtimes you control
- A self-hosted managed-agent platform for teams that keep agent data in their own infrastructure
- A foundation for custom agent workflows such as code review, automated testing, and operations runbooks

## Dependencies for Multica Hosting

- A Railway account
- The Multica CLI on each machine where agents should run: `brew install multica-ai/tap/multica`
- Optional: a Resend API key or SMTP credentials to email login codes, and Google OAuth credentials for social login

### Deployment Dependencies

- Multica upstream repository: https://github.com/multica-ai/multica
- Multica self-hosting guide: https://multica.ai/docs/self-host-quickstart
- Template repository: https://github.com/RockinPaul/multica_railway_template
- pgvector image: https://hub.docker.com/r/pgvector/pgvector

### Implementation Details

- `frontend`: `ghcr.io/multica-ai/multica-web:v0.4.41`, healthcheck `/`, public domain. Proxies `/api`, `/auth`, `/uploads`, and `/health` to the backend over the private network, so the browser only ever talks to the frontend domain.
- `backend`: `ghcr.io/multica-ai/multica-backend:v0.4.41`, healthcheck `/readyz`, public domain (the CLI daemon connects here), volume at `/app/data/uploads`. Runs `migrate up` before serving.
- `pgvector`: `pgvector/pgvector:pg17`, volume at `/var/lib/postgresql/data`.

First login: open the frontend domain, enter your email, and read the code from the backend logs (`railway logs --service backend --filter "Verification code"`). If the instance is private, set `ALLOW_SIGNUP=false` or an `ALLOWED_EMAILS` / `ALLOWED_EMAIL_DOMAINS` allow-list afterwards.

Live updates work on the default domains: the web image proxies the browser's WebSocket to the backend over the private network. Two optional variables, `COOKIE_DOMAIN` on `backend` and `NEXT_PUBLIC_WS_URL` on `frontend`, ship empty for setups where the browser should reach the backend host directly; the template README explains when to set them.

### Upgrading from an earlier version

Deployments created before September 2026 built Multica v0.2.16 from a vendored source snapshot. Back up the `pgvector` service before applying the update: migrations run automatically on the first start and are forward-only. Steps and details: https://github.com/RockinPaul/multica_railway_template/blob/main/CHANGELOG.md

## Why Deploy Multica on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Multica on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
