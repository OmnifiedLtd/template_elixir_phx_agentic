defmodule PhxAgenticTemplateWeb.QueueLiveTest do
  use PhxAgenticTemplateWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders queue dashboard", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/queues")

    assert html =~ "Queue States"
    assert has_element?(view, "#queue-demo-default")
  end

  test "enqueues demo jobs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/queues")

    view
    |> element("#queue-demo-default")
    |> render_click()

    assert render(view) =~ "Enqueued"
  end
end
