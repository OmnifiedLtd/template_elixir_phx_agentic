defmodule PhxAgenticTemplate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhxAgenticTemplateWeb.Telemetry,
      PhxAgenticTemplate.Repo,
      {DNSCluster,
       query: Application.get_env(:phx_agentic_template, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhxAgenticTemplate.PubSub},
      {Oban, Application.fetch_env!(:phx_agentic_template, Oban)},
      # Start a worker by calling: PhxAgenticTemplate.Worker.start_link(arg)
      # {PhxAgenticTemplate.Worker, arg},
      # Start to serve requests, typically the last entry
      PhxAgenticTemplateWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhxAgenticTemplate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhxAgenticTemplateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
