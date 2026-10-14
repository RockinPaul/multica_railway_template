# Multica backend (API, realtime, daemon hub) for Railway.
# Upgrade Multica by bumping this tag; keep it equal to the tag in Dockerfile.web.
# The image's entrypoint runs `migrate up`, then the server, listening on $PORT.
FROM ghcr.io/multica-ai/multica-backend:v0.6.2

# Upstream turned on a daily anonymous deployment snapshot in v0.4.44 that only
# DO_NOT_TRACK stops; ANALYTICS_DISABLED (a template variable) covers the
# separate product analytics. Set here so updates keep both off. A service
# variable DO_NOT_TRACK=false opts back in.
ENV DO_NOT_TRACK=true
