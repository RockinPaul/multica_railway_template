# Changelog

## 2026-10 — Multica v0.6.2

- `backend` runs `ghcr.io/multica-ai/multica-backend:v0.6.2` and `frontend` runs `ghcr.io/multica-ai/multica-web:v0.6.2` (both were v0.4.41).
- Security fixes since v0.4.41 include Next.js advisories in the web image, upgraded Alpine OpenSSL packages, and a channel fix that refuses an inbound turn from a member who may not run the agent.
- **Telemetry stays off.** v0.4.44 added a daily anonymous deployment snapshot to `telemetry.multica.ai`, on by default, that `ANALYTICS_DISABLED` does not cover. `Dockerfile` now sets `DO_NOT_TRACK=true`, so it stays off on new and existing deployments. Set `DO_NOT_TRACK=false` on `backend` to opt in.
- New optional backend variables, all off when unset: `DISABLE_WORKSPACE_CREATION`, `REDIS_URL`, `MULTICA_LLM_DISABLE_THINKING`, and the DingTalk and Telegram integration keys. See upstream's `SELF_HOSTING_ADVANCED.md`.

### Upgrading an existing deployment

Your data stays. **Back up `pgvector` first**: the new `backend` applies 119 forward-only migrations on its first start (up to `572_channel_typing_abandoned_idx`; about a second on a small database). Rolling back the deployment does not undo them. The old v0.4.41 backend still starts against the migrated database and reports `/readyz` ok, so a rollback looks healthy while it runs against a schema it does not know; a real rollback means restoring the backup.

1. Apply the update from Railway's banner. Both services redeploy; nothing compiles.
2. Check `https://<backend-domain>/readyz` returns `{"status":"ok","checks":{"db":"ok","migrations":"ok"}}`. Existing sessions and personal access tokens stay valid because `JWT_SECRET` does not change.
3. **Runtimes**: upgrade the Multica CLI on machines running the daemon (`brew upgrade multica`). The v0.6 daemon refuses OpenCode older than 1.1.54, because older builds leave a native module in the shared temp directory on every run until the disk fills; upgrade OpenCode on runtimes that use it.
4. `ALLOW_SIGNUP=false` no longer stops a signed-in user from creating another workspace. Set `DISABLE_WORKSPACE_CREATION=true` on `backend` if you want that locked down too. Invited emails can now sign up while `ALLOW_SIGNUP=false`.

## 2026-09 — Multica v0.4.41 from upstream images

**Read "Upgrading an existing deployment" below before applying this update.**

- `backend` runs the upstream image `ghcr.io/multica-ai/multica-backend:v0.4.41` and `frontend` runs `ghcr.io/multica-ai/multica-web:v0.4.41`. Previously this repo vendored a Multica source snapshot from 2026-04-25 (v0.2.16) and Railway compiled both services on every deploy. Deploys now take about a minute instead of ten to fifteen per service.
- Removed: the vendored source tree, `railway/backend.railway.json` and `railway/frontend.railway.json` (Config-as-Code, deprecated by Railway and never wired into the template), and `railway/README.md` (now `TEMPLATE_OVERVIEW.md`).
- Removed template variable `NEXT_PUBLIC_APP_VERSION` on `frontend`. It was a build-time value; the image carries its own version.
- Fixed: `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET` defaulted to a single space. The backend does not trim `RESEND_API_KEY`, so every fresh deploy answered "failed to send verification code" (HTTP 500) at login until the deployer cleared the value, and `GOOGLE_CLIENT_ID` reached the web app as a space. They now default to empty.
- New on `backend`: `MULTICA_DAEMON_SERVER_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}`, so the runtime setup page in the web app shows a `multica setup self-host` command that points the daemon at the backend instead of the frontend.
- New optional variables, empty by default: `NEXT_PUBLIC_WS_URL` on `frontend` and `COOKIE_DOMAIN` on `backend`, for deployments where the browser reaches the backend host directly (custom subdomains of one domain). Not needed on Railway domains: realtime updates work through the frontend proxy, verified on v0.4.41.

### Upgrading an existing deployment

Your data stays. Railway's update redeploys `frontend` and `backend` by pulling the upstream images named in the new Dockerfiles; it never touches `pgvector`, its volume, or the uploads volume.

**Back up `pgvector` first** (Railway → pgvector service → Backups → Create backup, or `railway connect pgvector` and `pg_dump`). The update is one-way: Multica's migrations are forward-only. Rolling back the `backend` deployment in Railway does not undo them. In the rehearsal the old v0.2.16 server did start against the migrated database and even reported `/readyz` ok, but it logged errors such as `column "last_heartbeat_at" does not exist` and parts of the app stop working. A real rollback means restoring the backup, then rolling back both deployments.

1. **Migrations run themselves.** On its first start the new `backend` applies every migration added since April, 405 of them (74 to 479). In the rehearsal on a small database this took a few seconds. The `/readyz` healthcheck stays red until `db` and `migrations` both report `ok`, so Railway keeps the old deployment live if the migration fails; check the backend logs in that case.
2. **Apply the update** from the banner Railway shows on the project. Both services redeploy. Nothing compiles anymore, so in the rehearsal both were live 55 seconds after the update started.
3. **Check** `https://<backend-domain>/readyz` returns `{"status":"ok","checks":{"db":"ok","migrations":"ok"}}` and open the frontend. Existing sessions and personal access tokens stay valid, because `JWT_SECRET` does not change. Workspaces and issues created on v0.2.16 were all present after the rehearsal upgrade.
4. **Optional variable cleanup** on `backend`: if `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `GOOGLE_CLIENT_ID`, or `GOOGLE_CLIENT_SECRET` still hold a single space, clear them (or set real values). Add `MULTICA_DAEMON_SERVER_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}` so the web app shows the right daemon setup command. On `frontend`, `NEXT_PUBLIC_APP_VERSION` can be deleted.
5. **Runtimes**: upgrade the Multica CLI on machines running the daemon (`brew upgrade multica`) so it matches the server release.
