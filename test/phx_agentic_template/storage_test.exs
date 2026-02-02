defmodule PhxAgenticTemplate.StorageTest do
  use ExUnit.Case, async: true

  alias PhxAgenticTemplate.Storage

  setup do
    Application.put_env(:phx_agentic_template, Storage,
      bucket: "test-bucket",
      endpoint: "https://fly.storage.tigris.dev",
      request: PhxAgenticTemplate.Storage.Mock
    )

    on_exit(fn ->
      Application.delete_env(:phx_agentic_template, Storage)
    end)

    :ok
  end

  test "builds S3 operations with configured bucket" do
    operation = Storage.put_object_op("demo.txt", "hi")

    assert %ExAws.Operation.S3{bucket: "test-bucket", path: "demo.txt"} = operation
  end

  test "put_object uses the request adapter" do
    {:ok, %{operation: operation}} = Storage.put_object("demo.txt", "hello")

    assert %ExAws.Operation.S3{bucket: "test-bucket"} = operation
  end
end
