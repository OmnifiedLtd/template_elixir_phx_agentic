defmodule PhxAgenticTemplateWeb.StorageLiveTest do
  use PhxAgenticTemplateWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup do
    Application.put_env(:phx_agentic_template, PhxAgenticTemplate.Storage,
      bucket: "test-bucket",
      endpoint: "https://fly.storage.tigris.dev",
      request: PhxAgenticTemplate.Storage.Mock
    )

    on_exit(fn ->
      Application.delete_env(:phx_agentic_template, PhxAgenticTemplate.Storage)
    end)

    :ok
  end

  test "uploads objects", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/storage")

    assert html =~ "Bucket"

    view
    |> form("#storage-upload-form", upload: %{key: "demo.txt", content: "hello"})
    |> render_submit()

    assert render(view) =~ "Uploaded"
  end
end
