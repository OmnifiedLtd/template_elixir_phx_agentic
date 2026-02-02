defmodule PhxAgenticTemplateWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PhxAgenticTemplateWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen">
      <header class="sticky top-0 z-20 border-b border-slate-200/70 bg-white/80 backdrop-blur">
        <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
          <div class="flex items-center gap-3">
            <.link navigate={~p"/"} class="flex items-center gap-2">
              <img src={~p"/images/logo.svg"} width="36" height="36" />
              <div class="leading-tight">
                <div class="text-sm font-semibold text-slate-900">Phx Agentic Template</div>
                <div class="text-xs text-slate-400">
                  Phoenix v{Application.spec(:phoenix, :vsn)}
                </div>
              </div>
            </.link>
          </div>

          <nav class="flex flex-wrap items-center gap-3 text-sm text-slate-600">
            <%= if @current_scope && @current_scope.user do %>
              <.link navigate={~p"/queues"} class="transition hover:text-slate-900">
                Queues
              </.link>
              <.link navigate={~p"/storage"} class="transition hover:text-slate-900">
                Storage
              </.link>
              <.link href={~p"/users/settings"} class="transition hover:text-slate-900">
                Settings
              </.link>
              <span class="hidden text-xs text-slate-400 sm:inline">
                {@current_scope.user.email}
              </span>
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Log out
              </.link>
            <% else %>
              <.link
                href={~p"/users/register"}
                class="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Register
              </.link>
              <.link
                href={~p"/users/log-in"}
                class="rounded-full bg-slate-900 px-3 py-1 text-xs font-semibold text-white transition hover:bg-slate-800"
              >
                Log in
              </.link>
            <% end %>

            <.theme_toggle />
          </nav>
        </div>
      </header>

      <main class="px-4 py-12 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-6xl">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center gap-1 rounded-full border border-slate-200 bg-white p-1 text-slate-500">
      <button
        class="flex items-center justify-center rounded-full px-2 py-1 text-xs font-semibold transition hover:bg-slate-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center rounded-full px-2 py-1 text-xs font-semibold transition hover:bg-slate-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center rounded-full px-2 py-1 text-xs font-semibold transition hover:bg-slate-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end
end
