defmodule PhxAgenticTemplateWeb.QueueLive.Index do
  use PhxAgenticTemplateWeb, :live_view

  alias PhxAgenticTemplate.Queues

  @refresh_interval_ms 2_000
  @job_states ~w(available scheduled executing retryable completed cancelled discarded)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_interval_ms, self(), :refresh)
    end

    {:ok, assign_data(socket)}
  end

  @impl true
  def handle_event("queue-action", %{"queue" => queue, "action" => action}, socket) do
    past_tense =
      case action do
        "start" -> "started"
        "stop" -> "stopped"
        "pause" -> "paused"
        "resume" -> "resumed"
        _ -> "updated"
      end

    result =
      case action do
        "start" -> Queues.start_queue(queue)
        "stop" -> Queues.stop_queue(queue)
        "pause" -> Queues.pause_queue(queue)
        "resume" -> Queues.resume_queue(queue)
        _ -> {:error, :unsupported}
      end

    socket =
      case result do
        {:ok, _} -> put_flash(socket, :info, "Queue #{queue} #{past_tense}.")
        :ok -> put_flash(socket, :info, "Queue #{queue} #{past_tense}.")
        {:error, reason} -> put_flash(socket, :error, "Queue action failed: #{inspect(reason)}")
      end

    {:noreply, assign_data(socket)}
  end

  def handle_event("enqueue-demo", %{"queue" => queue, "count" => count}, socket) do
    count = String.to_integer(count)
    jobs = Queues.enqueue_demo_jobs(queue, count)
    socket = put_flash(socket, :info, "Enqueued #{length(jobs)} demo jobs in #{queue}.")

    {:noreply, assign_data(socket)}
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, assign_data(socket)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, assign_data(socket)}
  end

  defp assign_data(socket) do
    assign(socket,
      page_title: "Queues",
      queues: Queues.list_queues(),
      job_counts: Queues.queue_job_counts(),
      job_states: @job_states,
      last_refreshed_at: DateTime.utc_now()
    )
  end

  defp status_label(:running), do: "Running"
  defp status_label(:paused), do: "Paused"
  defp status_label(:stopped), do: "Stopped"

  defp status_class(:running), do: "bg-emerald-100 text-emerald-800"
  defp status_class(:paused), do: "bg-amber-100 text-amber-800"
  defp status_class(:stopped), do: "bg-slate-200 text-slate-700"

  defp timestamp(nil), do: "—"

  defp timestamp(value) do
    Calendar.strftime(value, "%Y-%m-%d %H:%M:%S UTC")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-5xl space-y-10" id="queues-page">
        <section class="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div class="space-y-2">
            <p class="text-xs uppercase tracking-[0.3em] text-slate-400">Oban Control</p>
            <h1 class="text-3xl font-semibold text-slate-900">Queues</h1>
            <p class="text-sm text-slate-500">
              Start, pause, and monitor queues in real time. Updated every 2 seconds.
            </p>
          </div>
          <button
            id="queues-refresh"
            phx-click="refresh"
            class="inline-flex items-center justify-center rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
          >
            Refresh now
          </button>
        </section>

        <section class="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
          <div class="border-b border-slate-100 px-6 py-4">
            <div class="flex items-center justify-between">
              <h2 class="text-base font-semibold text-slate-900">Queue States</h2>
              <p class="text-xs text-slate-400">Last updated: {timestamp(@last_refreshed_at)}</p>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
              <thead class="bg-slate-50 text-xs uppercase tracking-wider text-slate-500">
                <tr>
                  <th class="px-6 py-3">Queue</th>
                  <th class="px-6 py-3">Status</th>
                  <th class="px-6 py-3">Running</th>
                  <th class="px-6 py-3">Limit</th>
                  <th class="px-6 py-3">Updated</th>
                  <th class="px-6 py-3">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <%= for queue <- @queues do %>
                  <tr class="hover:bg-slate-50/60">
                    <td class="px-6 py-4 font-medium text-slate-900">
                      {queue.name}
                    </td>
                    <td class="px-6 py-4">
                      <span class={"inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold #{status_class(queue.status)}"}>
                        {status_label(queue.status)}
                      </span>
                    </td>
                    <td class="px-6 py-4 text-slate-600">{queue.running}</td>
                    <td class="px-6 py-4 text-slate-600">{queue.limit}</td>
                    <td class="px-6 py-4 text-slate-500">{timestamp(queue.updated_at)}</td>
                    <td class="px-6 py-4">
                      <div class="flex flex-wrap gap-2">
                        <button
                          id={"queue-start-#{queue.name}"}
                          phx-click="queue-action"
                          phx-value-queue={queue.name}
                          phx-value-action="start"
                          class="rounded-full border border-emerald-200 px-3 py-1 text-xs font-semibold text-emerald-700 transition hover:border-emerald-300 hover:text-emerald-800"
                        >
                          Start
                        </button>
                        <button
                          id={"queue-stop-#{queue.name}"}
                          phx-click="queue-action"
                          phx-value-queue={queue.name}
                          phx-value-action="stop"
                          class="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-600 transition hover:border-slate-300 hover:text-slate-900"
                        >
                          Stop
                        </button>
                        <button
                          id={"queue-pause-#{queue.name}"}
                          phx-click="queue-action"
                          phx-value-queue={queue.name}
                          phx-value-action="pause"
                          class="rounded-full border border-amber-200 px-3 py-1 text-xs font-semibold text-amber-700 transition hover:border-amber-300 hover:text-amber-800"
                        >
                          Pause
                        </button>
                        <button
                          id={"queue-resume-#{queue.name}"}
                          phx-click="queue-action"
                          phx-value-queue={queue.name}
                          phx-value-action="resume"
                          class="rounded-full border border-sky-200 px-3 py-1 text-xs font-semibold text-sky-700 transition hover:border-sky-300 hover:text-sky-800"
                        >
                          Resume
                        </button>
                        <button
                          id={"queue-demo-#{queue.name}"}
                          phx-click="enqueue-demo"
                          phx-value-queue={queue.name}
                          phx-value-count="10"
                          class="rounded-full border border-violet-200 px-3 py-1 text-xs font-semibold text-violet-700 transition hover:border-violet-300 hover:text-violet-800"
                        >
                          Enqueue demo
                        </button>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-3xl border border-slate-200 bg-white px-6 py-6 shadow-sm">
          <h2 class="text-base font-semibold text-slate-900">Job Counts</h2>
          <p class="mt-1 text-sm text-slate-500">Live counts across job states per queue.</p>
          <div class="mt-6 grid gap-6 sm:grid-cols-2">
            <%= for queue <- @queues do %>
              <div class="rounded-2xl border border-slate-100 bg-slate-50/60 p-4">
                <div class="flex items-center justify-between">
                  <h3 class="text-sm font-semibold text-slate-900">{queue.name}</h3>
                  <span class="text-xs text-slate-400">
                    Total {get_in(@job_counts, [queue.name, "total"]) || 0}
                  </span>
                </div>
                <div class="mt-4 grid grid-cols-2 gap-3 text-xs text-slate-600">
                  <%= for state <- @job_states do %>
                    <div class="flex items-center justify-between rounded-lg bg-white px-3 py-2">
                      <span class="uppercase tracking-wide text-slate-400">{state}</span>
                      <span class="font-semibold text-slate-700">
                        {get_in(@job_counts, [queue.name, state]) || 0}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
