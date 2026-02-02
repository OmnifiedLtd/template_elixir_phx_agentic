defmodule PhxAgenticTemplate.Storage.Mock do
  @moduledoc false

  def request(operation, _config \\ nil) do
    {:ok, %{operation: operation, body: %{contents: []}}}
  end
end
