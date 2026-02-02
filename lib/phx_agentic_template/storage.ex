defmodule PhxAgenticTemplate.Storage do
  @moduledoc """
  Tigris object storage helpers via the ExAws S3 client.
  """

  alias ExAws.S3

  def configured? do
    bucket() not in [nil, ""] and endpoint() not in [nil, ""]
  end

  def bucket do
    Application.get_env(:phx_agentic_template, __MODULE__)[:bucket] ||
      System.get_env("BUCKET_NAME")
  end

  def endpoint do
    Application.get_env(:phx_agentic_template, __MODULE__)[:endpoint] ||
      System.get_env("AWS_ENDPOINT_URL_S3")
  end

  def put_object(key, body, opts \\ []) when is_binary(key) do
    put_object_op(key, body, opts)
    |> request()
  end

  def get_object(key, opts \\ []) when is_binary(key) do
    get_object_op(key, opts)
    |> request()
  end

  def list_objects(opts \\ []) do
    list_objects_op(opts)
    |> request()
    |> case do
      {:ok, %{body: %{contents: contents}}} ->
        {:ok, Enum.map(contents || [], &normalize_object/1)}

      {:ok, %{body: %{}}} ->
        {:ok, []}

      {:ok, %{body: nil}} ->
        {:ok, []}

      {:error, _reason} = error ->
        error
    end
  end

  def put_object_op(key, body, opts \\ []) do
    bucket!()
    |> S3.put_object(key, body, opts)
  end

  def get_object_op(key, opts \\ []) do
    bucket!()
    |> S3.get_object(key, opts)
  end

  def list_objects_op(opts \\ []) do
    bucket!()
    |> S3.list_objects(opts)
  end

  defp bucket! do
    case bucket() do
      nil -> raise "Tigris bucket is not configured. Set BUCKET_NAME."
      "" -> raise "Tigris bucket is not configured. Set BUCKET_NAME."
      bucket -> bucket
    end
  end

  defp request(operation) do
    request_mod = Application.get_env(:phx_agentic_template, __MODULE__)[:request] || ExAws

    cond do
      request_mod == ExAws ->
        request_mod.request(operation, config())

      function_exported?(request_mod, :request, 2) ->
        request_mod.request(operation, %{})

      true ->
        request_mod.request(operation)
    end
  end

  defp config do
    endpoint = endpoint()

    ExAws.Config.new(:s3,
      scheme: "https://",
      region: System.get_env("AWS_REGION") || "auto",
      host: endpoint_host(endpoint)
    )
  end

  defp endpoint_host(nil), do: nil

  defp endpoint_host(endpoint) do
    case URI.parse(endpoint) do
      %URI{host: nil} -> endpoint
      %URI{host: host} -> host
    end
  end

  defp normalize_object(%{key: key} = object) do
    %{
      key: key,
      size: Map.get(object, :size),
      etag: Map.get(object, :etag),
      last_modified: Map.get(object, :last_modified)
    }
  end
end
