# Changelog

## 2026-09 — Multica v0.4.41 from upstream images

**Read "Upgrading an existing deployment" below before applying this update.**

- `backend` runs the upstream image `ghcr.io/multica-ai/multica-backend:v0.4.41` and `frontend` runs `ghcr.io/multica-ai/multica-web:v0.4.41`. Previously this repo vendored a Multica source snapshot from 2026-04-25 (v0.2.16) and Railway compiled both services on every deploy. Deploys now take about a minute instead of ten to fifteen per service.
- Removed: the vendored source tree, `railway/backend.railway.json` and `railway/frontend.railway.json` (Config-as-Code, deprecated by Railway and never wired into the template), and `railway/README.md` (now `TEMPLATE_OVERVIEW.md`).
- Removed template variable `NEXT_PUBLIC_APP_VERSION` on `frontend`. It was a build-time value; the image carries its own version.
- Fixed: `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET` defaulted to a single space. The backend does not trim them, so every fresh deploy answered "failed to send verification code" (HTTP 500) at login until the deployer cleared the value, and the login page offered a Google button that could not work. They now default to empty.
- New on `backend`: `MULTICA_DAEMON_SERVER_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}`, so the runtime setup page in the web app shows a `multica setup self-host` command that points the daemon at the backend instead of the frontend.
- New optional variables, empty by default: `NEXT_PUBLIC_WS_URL` on `frontend` and `COOKIE_DOMAIN` on `backend`, for deployments where the browser reaches the backend host directly (custom subdomains of one domain). Not needed on Railway domains: realtime updates work through the frontend proxy, verified on v0.4.41.

### Upgrading an existing deployment

Your data stays. Railway's update rebuilds `frontend` and `backend` from the new Dockerfiles; it never touches `pgvector`, its volume, or the uploads volume.

**Back up `pgvector` first** (Railway → pgvector service → Backups → Create backup, or `railway connect pgvector` and `pg_dump`). The update is one-way: Multica's migrations are forward-only. Rolling back the `backend` deployment in Railway does not undo them. In the rehearsal the old v0.2.16 server did start against the migrated database and even reported `/readyz` ok, but it logged errors such as `column "last_heartbeat_at" does not exist` and parts of the app stop working. A real rollback means restoring the backup, then rolling back both deployments.

1. **Migrations run themselves.** On its first start the new `backend` applies every migration added since April, 405 of them (74 to 479). In the rehearsal on a small database this took a few seconds. The `/readyz` healthcheck stays red until `db` and `migrations` both report `ok`, so Railway keeps the old deployment live if the migration fails; check the backend logs in that case.
2. **Apply the update** from the banner Railway shows on the project. Both services redeploy. Nothing compiles anymore, so in the rehearsal both were live 55 seconds after the update started.
3. **Check** `https://<backend-domain>/readyz` returns `{"status":"ok","checks":{"db":"ok","migrations":"ok"}}` and open the frontend. Existing sessions and personal access tokens stay valid, because `JWT_SECRET` does not change. Workspaces and issues created on v0.2.16 were all present after the rehearsal upgrade.
4. **Optional variable cleanup** on `backend`: if `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `GOOGLE_CLIENT_ID`, or `GOOGLE_CLIENT_SECRET` still hold a single space, clear them (or set real values). Add `MULTICA_DAEMON_SERVER_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}` so the web app shows the right daemon setup command. On `frontend`, `NEXT_PUBLIC_APP_VERSION` can be deleted.
5. **Runtimes**: upgrade the Multica CLI on machines running the daemon (`brew upgrade multica`) so it matches the server release.
