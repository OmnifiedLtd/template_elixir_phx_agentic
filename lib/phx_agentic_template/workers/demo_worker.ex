defmodule PhxAgenticTemplate.Workers.DemoWorker do
  @moduledoc """
  Simulates work for queue demos and live stats.
  """

  use Oban.Worker, queue: :default, max_attempts: 1

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"label" => label, "duration_ms" => duration_ms}}) do
    Logger.info("demo job #{label} sleeping for #{duration_ms}ms")
    Process.sleep(duration_ms)
    {:ok, %{label: label, duration_ms: duration_ms}}
  end

  def perform(%Oban.Job{args: args}) do
    {:ok, %{args: args}}
  end
end
