defmodule PhxAgenticTemplateWeb.PageController do
  use PhxAgenticTemplateWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
