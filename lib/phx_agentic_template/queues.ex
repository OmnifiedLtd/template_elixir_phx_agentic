defmodule PhxAgenticTemplate.Queues do
  @moduledoc """
  Provides queue control and stats for Oban.
  """

  import Ecto.Query

  alias PhxAgenticTemplate.Repo
  alias PhxAgenticTemplate.Workers.DemoWorker
  alias Oban.Job

  @job_states ~w(available scheduled executing retryable completed cancelled discarded)

  def list_queues do
    queue_limits = configured_queue_limits()
    state_by_queue = Map.new(Oban.check_all_queues(), &{&1.queue, &1})

    queue_names =
      queue_limits
      |> Map.keys()
      |> Enum.concat(Map.keys(state_by_queue))
      |> Enum.uniq()

    queue_names
    |> Enum.map(fn queue_name ->
      state = Map.get(state_by_queue, queue_name)

      %{
        name: queue_name,
        limit: queue_limit(queue_name, queue_limits, state),
        status: queue_status(state),
        running: running_count(state),
        updated_at: state && state.updated_at
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  def queue_job_counts do
    base = configured_queue_limits()
    queue_names = Map.keys(base)

    initial =
      queue_names
      |> Enum.map(&{&1, zero_counts()})
      |> Map.new()

    counts =
      Job
      |> select([j], {j.queue, j.state, count(j.id)})
      |> group_by([j], [j.queue, j.state])
      |> Repo.all()

    counts
    |> Enum.reduce(initial, fn {queue, state, count}, acc ->
      Map.update(acc, queue, zero_counts(), fn states ->
        Map.put(states, state, count)
      end)
    end)
    |> Map.new(fn {queue, states} ->
      total = Enum.reduce(@job_states, 0, fn state, sum -> sum + Map.get(states, state, 0) end)
      {queue, Map.put(states, "total", total)}
    end)
  end

  def start_queue(queue) when is_binary(queue), do: Oban.start_queue(queue: queue)

  def stop_queue(queue) when is_binary(queue), do: Oban.stop_queue(queue: queue)

  def pause_queue(queue) when is_binary(queue), do: Oban.pause_queue(queue: queue)

  def resume_queue(queue) when is_binary(queue), do: Oban.resume_queue(queue: queue)

  def enqueue_demo_jobs(queue, count \\ 10) when is_binary(queue) and is_integer(count) do
    1..count
    |> Enum.map(fn index ->
      DemoWorker.new(
        %{label: "demo-#{index}", duration_ms: Enum.random(400..2200)},
        queue: queue
      )
    end)
    |> Oban.insert_all()
  end

  def configured_queue_limits do
    config = Application.fetch_env!(:phx_agentic_template, Oban)

    queues =
      case Keyword.get(config, :queues, []) do
        false -> []
        nil -> []
        value -> value
      end

    queues
    |> Enum.map(fn {queue, limit} -> {to_string(queue), limit} end)
    |> Map.new()
  end

  defp queue_limit(queue_name, queue_limits, state) do
    cond do
      state && state.limit -> state.limit
      Map.has_key?(queue_limits, queue_name) -> Map.get(queue_limits, queue_name)
      true -> 0
    end
  end

  defp queue_status(nil), do: :stopped
  defp queue_status(%{paused: true}), do: :paused
  defp queue_status(_), do: :running

  defp running_count(nil), do: 0
  defp running_count(%{running: running}) when is_list(running), do: length(running)
  defp running_count(_), do: 0

  defp zero_counts do
    @job_states
    |> Enum.map(&{&1, 0})
    |> Map.new()
  end
end
