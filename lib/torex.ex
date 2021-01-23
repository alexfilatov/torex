defmodule Torex do
  use Application
  alias Torex.HTTPClient
  require Logger

  @tor_server Application.get_env(:torex, :tor_server)

  @moduledoc """
  Launches hackney pool with Tor proxy
  Acccording to docs should be working, but cannot assure it is
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :hackney_pool.child_spec(:torex_pool,
        timeout: 60_000,
        recv_timeout: 60_000,
        max_connections: 1_000
      )
    ]

    opts = [strategy: :one_for_one, name: Torex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get(url) do
    request(:get, url)
  end

  def post(url, params) do
    request(:post, url, Poison.encode!(params))
  end

  defp request(method, url, body \\ [], headers \\ []) when method == :get or method == :post do
    case HTTPClient.request(method, url, body, headers,
           hackney:
             [:insecure] ++
               [pool: :torex_pool, proxy: {:socks5, @tor_server[:ip], @tor_server[:port]}]
         ) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: status_code, body: body}} ->
        # TODO: implement this
        {:error, :wrong_status_code, status_code, body}

      {:error, %{reason: :econnrefused} = error} ->
        Logger.error("Please check Tor node is running and IP and PORT is correct in the config")
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end
end
