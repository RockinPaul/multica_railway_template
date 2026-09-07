# Multica backend (API, realtime, daemon hub) for Railway.
# Upgrade Multica by bumping this tag; keep it equal to the tag in Dockerfile.web.
# The image's entrypoint runs `migrate up`, then the server, listening on $PORT.
FROM ghcr.io/multica-ai/multica-backend:v0.4.41
