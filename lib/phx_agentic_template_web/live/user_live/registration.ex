defmodule PhxAgenticTemplateWeb.UserLive.Registration do
  use PhxAgenticTemplateWeb, :live_view

  alias PhxAgenticTemplate.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <div :if={@password_auth_enabled} class="alert alert-warning mt-4">
          <.icon name="hero-exclamation-triangle" class="size-6 shrink-0" />
          <div>
            <p>Password sign-in is enabled for production testing.</p>
            <p>
              Before go-live, disable it with <code>PASSWORD_AUTH_ENABLED=false</code> and
              switch to magic links.
            </p>
          </div>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <div :if={@password_auth_enabled} class="space-y-4">
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
            />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm password"
              autocomplete="new-password"
              required
            />
          </div>

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: PhxAgenticTemplateWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    password_auth_enabled = Accounts.password_auth_enabled?()

    changeset =
      Accounts.change_user_registration(%{},
        validate_unique: false,
        password_auth_enabled: password_auth_enabled
      )

    {:ok,
     socket
     |> assign(:password_auth_enabled, password_auth_enabled)
     |> assign_form(changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        if socket.assigns.password_auth_enabled do
          {:noreply,
           socket
           |> put_flash(:info, "Account created. Log in with your password.")
           |> push_navigate(to: ~p"/users/log-in")}
        else
          case Accounts.deliver_login_instructions(
                 user,
                 &url(~p"/users/log-in/#{&1}")
               ) do
            {:ok, _} ->
              {:noreply,
               socket
               |> put_flash(
                 :info,
                 "An email was sent to #{user.email}, please access it to confirm your account."
               )
               |> push_navigate(to: ~p"/users/log-in")}

            {:error, _reason} ->
              {:noreply,
               socket
               |> put_flash(
                 :error,
                 "Your account was created, but we couldn't send the confirmation email. Please try logging in again shortly."
               )
               |> push_navigate(to: ~p"/users/log-in")}
          end
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_user_registration(user_params,
        validate_unique: false,
        password_auth_enabled: socket.assigns.password_auth_enabled
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
