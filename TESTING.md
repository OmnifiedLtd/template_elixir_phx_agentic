# Testing Guide

This project ships with full DB-backed tests using Ecto and Postgres.

## Quick Start

```
mix test
```

The default `test` alias runs:

- `mix ecto.create --quiet`
- `mix ecto.migrate --quiet`
- `mix test`

## Ensure Postgres Is Running

The test database config is in `config/test.exs` and expects:

- `username: postgres`
- `password: postgres`
- `hostname: localhost`

Update these values if your local Postgres differs.

## Clean Test Database (Optional)

If you want a clean slate before running tests:

```
MIX_ENV=test mix ecto.drop
```

Then run:

```
mix test
```

## Run a Single Test File

```
mix test test/phx_agentic_template/queues_test.exs
```

## Run a Single Test

```
mix test test/phx_agentic_template_web/live/queue_live_test.exs:1
```

## Oban Testing

In `config/test.exs`, Oban runs in `testing: :manual` mode. Use `Oban.Testing` helpers for
predictable execution without background workers.

## First-Run Checklist

1. Run `mix deps.get`.
2. Verify Postgres is running locally.
3. Run `mix ecto.create`.
4. Run `mix ecto.migrate`.
5. Start the server with `mix phx.server`.
6. Register a user at `/users/register`.
7. Visit `/queues` and click “Enqueue demo” to see stats update.
8. Set Tigris env vars and visit `/storage` to upload an object.

## CI Notes

- The CI workflow is `.github/workflows/ci.yml`.
- It runs `mix format --check-formatted` and `mix test`.
- CI spins up Postgres via a service container. If you change DB credentials in
  `config/test.exs`, update the CI service env to match.

## Fly.io Deployment Checks

1. Update `fly.toml` with your Fly app name and `PHX_HOST`.
2. Create a Postgres database: `fly postgres create`.
3. Attach Postgres and set `DATABASE_URL` (the Fly PG attach step does this for you).
4. Provision Tigris storage: `fly storage create`.
5. Verify secrets: `fly secrets list` and ensure `AWS_ACCESS_KEY_ID`,
   `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `BUCKET_NAME`,
   `SECRET_KEY_BASE`, and `DATABASE_URL` exist.
6. Deploy: `fly deploy`.
7. Validate `/queues` and `/storage` in production.
