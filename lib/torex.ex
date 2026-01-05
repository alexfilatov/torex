defmodule Torex do
  @moduledoc """
  Simple HTTP client for making requests through the Tor network.

  ## Configuration

      config :torex,
        tor_host: ~c"127.0.0.1",
        tor_port: 9050,
        # Optional: for circuit renewal
        control_port: 9051,
        control_password: "your_password"

  ## Usage

      {:ok, body} = Torex.get("http://example.onion")
      {:ok, body} = Torex.post("http://example.onion", %{key: "value"})

  ## Circuit Renewal

  To get a new exit node IP (useful for scraping):

      :ok = Torex.renew_circuit()
  """

  require Logger

  @doc """
  Makes a GET request through Tor.
  """
  def get(url) do
    request(:get, url)
  end

  @doc """
  Makes a POST request through Tor with JSON-encoded body.
  """
  def post(url, params) do
    request(:post, url, Jason.encode!(params), [{"content-type", "application/json"}])
  end

  @doc """
  Requests a new Tor circuit, giving you a fresh exit node IP.

  Useful for scraping when you need to rotate IPs. Note that Tor
  rate-limits this to once per 10 seconds.

  Requires Tor control port to be enabled. See `Torex.Control` for setup.

  ## Examples

      :ok = Torex.renew_circuit()

      # Get new IP and make request
      :ok = Torex.renew_circuit()
      {:ok, body} = Torex.get("https://api.ipify.org")
  """
  defdelegate renew_circuit(), to: Torex.Control

  defp request(method, url, body \\ "", headers \\ []) do
    proxy = {:socks5, tor_host(), tor_port()}
    options = [hackney: [:insecure, pool: :torex_pool, proxy: proxy]]

    case http_client().request(method, url, body, headers, options) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, %{reason: :econnrefused} = error} ->
        Logger.error("Tor connection refused. Ensure Tor is running on #{inspect(tor_host())}:#{tor_port()}")
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  defp http_client do
    Application.get_env(:torex, :http_client, Torex.HTTPClient)
  end

  defp tor_host do
    Application.get_env(:torex, :tor_host, ~c"127.0.0.1")
  end

  defp tor_port do
    Application.get_env(:torex, :tor_port, 9050)
  end
end
