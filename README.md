# PhxAgenticTemplate

A Phoenix 1.8 template for AI-automated development with LiveView, Oban queues, auth by default,
Fly.io deployment, and Tigris object storage.

## What’s Included

- Phoenix 1.8 + LiveView 1.1
- Oban 2.20 with live queue controls and stats
- LiveView-based authentication (`mix phx.gen.auth --live`)
- Tigris S3-compatible storage example
- Fly.io deployment config + GitHub Actions
- Agent guidance in `AGENTS.md`

## Local Setup

1. Install dependencies

```
mix deps.get
```

2. Create and migrate the database

```
mix ecto.create
mix ecto.migrate
```

3. Start the server

```
mix phx.server
```

Visit `http://localhost:4000` and register an account at `/users/register`.

## Email Delivery (SMTP)

Production email delivery uses the SMTP adapter. Configure these Fly.io secrets:

- `SMTP_RELAY`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_PORT` (defaults to `587`)
- `SMTP_SSL` (`true` or `false`)

Example:

```
fly secrets set SMTP_RELAY="smtp.example.com" SMTP_USERNAME="user" SMTP_PASSWORD="pass" SMTP_PORT="587" SMTP_SSL="false"
```

If email delivery fails, the app logs the error and shows a friendly message instead of crashing.

## Queue Dashboard

The queue dashboard is available at `/queues` after login. It allows you to:

- Start/stop/pause/resume queues
- Enqueue demo jobs
- View live job counts per queue

## Tigris Object Storage

The storage example is available at `/storage` after login. To enable it locally, export:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ENDPOINT_URL_S3` (e.g. `https://fly.storage.tigris.dev`)
- `AWS_REGION`
- `BUCKET_NAME`

On Fly.io, run:

```
fly storage create
```

That command provisions a bucket and sets the required secrets on the app.

## Tests

```
mix test
```

## Secrets Checklist

GitHub Actions:

- `FLY_API_TOKEN` (required for deploy workflow)

Fly.io app secrets (set by `fly launch`, `fly postgres attach`, and `fly storage create`):

- `DATABASE_URL`
- `SECRET_KEY_BASE`
- `SMTP_RELAY`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_PORT`
- `SMTP_SSL`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ENDPOINT_URL_S3`
- `AWS_REGION`
- `BUCKET_NAME`

Local testing (optional):

- No extra secrets required. Tests use a storage mock and local Postgres credentials from `config/test.exs`.

## Fly.io Deployment

1. Update `fly.toml` with your app name and `PHX_HOST`.
2. Ensure `PHX_SERVER=true` is set in `fly.toml`.
3. Provision Postgres and Tigris storage:

```
fly postgres create
fly storage create
```

4. Deploy:

```
fly deploy
```

## GitHub Actions Deployment

The workflow in `.github/workflows/deploy.yml` deploys on push to `main`.
Set `FLY_API_TOKEN` as a repository secret.

## Agentic Development

See `AGENTS.md` for guidance on Ecto migrations, Oban workflows, LiveView practices,
and MCP usage for Tidewave, Playwright, and Fly.io.

### MCP Setup (Codex)

This repo includes a project-scoped MCP config at `.codex/config.toml`. For Codex to load it,
mark this project as **trusted** in your global Codex settings.

Fly MCP server (optional):

```
fly mcp server --stream --bind-addr 127.0.0.1 --port 8080
```
