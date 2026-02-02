defmodule PhxAgenticTemplate.Repo do
  use Ecto.Repo,
    otp_app: :phx_agentic_template,
    adapter: Ecto.Adapters.Postgres
end
