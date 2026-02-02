defmodule PhxAgenticTemplateWeb.StorageLive.Index do
  use PhxAgenticTemplateWeb, :live_view

  alias PhxAgenticTemplate.Storage

  @impl true
  def mount(_params, _session, socket) do
    socket = assign_storage(socket)
    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"upload" => params}, socket) do
    changeset = upload_changeset(params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(changeset, as: :upload))}
  end

  def handle_event("upload", %{"upload" => params}, socket) do
    changeset = upload_changeset(params)

    if changeset.valid? do
      %{key: key, content: content} = Ecto.Changeset.apply_changes(changeset)

      socket =
        case Storage.put_object(key, content) do
          {:ok, _} ->
            socket
            |> put_flash(:info, "Uploaded #{key} to Tigris.")
            |> assign_storage()

          {:error, reason} ->
            put_flash(socket, :error, "Upload failed: #{inspect(reason)}")
        end

      {:noreply, socket}
    else
      {:noreply, assign(socket, form: to_form(changeset, as: :upload))}
    end
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, assign_storage(socket)}
  end

  defp assign_storage(socket) do
    configured = Storage.configured?()

    objects =
      if configured do
        case Storage.list_objects() do
          {:ok, objects} -> objects
          {:error, _reason} -> []
        end
      else
        []
      end

    assign(socket,
      page_title: "Storage",
      configured: configured,
      bucket: Storage.bucket(),
      endpoint: Storage.endpoint(),
      objects: objects,
      form: to_form(upload_changeset(%{}), as: :upload)
    )
  end

  defp upload_changeset(params) do
    types = %{key: :string, content: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:key, :content])
    |> Ecto.Changeset.validate_length(:key, min: 2)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl space-y-10" id="storage-page">
        <section class="space-y-3">
          <p class="text-xs uppercase tracking-[0.3em] text-slate-400">Tigris Storage</p>
          <h1 class="text-3xl font-semibold text-slate-900">Object Storage</h1>
          <p class="text-sm text-slate-500">
            This example uses ExAws + Tigris to upload and list objects from Fly.io storage.
          </p>
        </section>

        <%= if @configured do %>
          <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p class="text-xs uppercase tracking-widest text-slate-400">Bucket</p>
                <p class="text-sm font-semibold text-slate-900">{@bucket}</p>
                <p class="text-xs text-slate-400">Endpoint: {@endpoint}</p>
              </div>
              <button
                id="storage-refresh"
                phx-click="refresh"
                class="rounded-full border border-slate-200 px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Refresh list
              </button>
            </div>

            <div class="mt-6 grid gap-6 lg:grid-cols-[1.2fr_1fr]">
              <div class="rounded-2xl border border-slate-100 bg-slate-50/60 p-4">
                <h2 class="text-sm font-semibold text-slate-900">Upload a new object</h2>
                <.form
                  for={@form}
                  id="storage-upload-form"
                  phx-change="validate"
                  phx-submit="upload"
                  class="mt-4 space-y-4"
                >
                  <.input field={@form[:key]} label="Object key" placeholder="demo/hello.txt" />
                  <.input
                    field={@form[:content]}
                    type="textarea"
                    label="Content"
                    placeholder="Hello from Phoenix + Tigris"
                  />
                  <button
                    type="submit"
                    class="inline-flex items-center justify-center rounded-full bg-slate-900 px-4 py-2 text-xs font-semibold uppercase tracking-widest text-white transition hover:bg-slate-800"
                  >
                    Upload object
                  </button>
                </.form>
              </div>

              <div class="rounded-2xl border border-slate-100 bg-slate-50/60 p-4">
                <h2 class="text-sm font-semibold text-slate-900">Objects in bucket</h2>
                <%= if Enum.empty?(@objects) do %>
                  <p class="mt-3 text-sm text-slate-500">No objects yet.</p>
                <% else %>
                  <ul class="mt-3 space-y-3 text-sm text-slate-700">
                    <%= for object <- @objects do %>
                      <li class="rounded-xl border border-slate-200 bg-white px-3 py-2">
                        <div class="font-medium text-slate-900">{object.key}</div>
                        <div class="text-xs text-slate-400">
                          Size {object.size || "?"} bytes
                        </div>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
              </div>
            </div>
          </section>
        <% else %>
          <section class="rounded-3xl border border-amber-200 bg-amber-50 px-6 py-6 text-amber-900">
            <h2 class="text-sm font-semibold uppercase tracking-widest">Storage not configured</h2>
            <p class="mt-2 text-sm">
              Set `BUCKET_NAME` and `AWS_ENDPOINT_URL_S3` (plus credentials) to enable Tigris
              storage. See the README for `fly storage create` setup.
            </p>
          </section>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
