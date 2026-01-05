# Torex

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/alexfilatov/torex/tree/master.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/alexfilatov/torex/tree/master)
[![Hex.pm](https://img.shields.io/hexpm/v/torex.svg)](https://hex.pm/packages/torex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/torex)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/torex.svg)](https://hex.pm/packages/torex)
[![License](https://img.shields.io/hexpm/l/torex.svg)](https://opensource.org/licenses/MIT)

Elixir HTTP client for making requests through the Tor network. Wraps HTTPoison with SOCKS5 proxy support for routing traffic through a local Tor node.

## Requirements

- Elixir 1.14+
- A running Tor node

## Installation

Add `torex` to your dependencies in `mix.exs`:

```elixir
def deps do
  [{:torex, "~> 0.2.0"}]
end
```

## Tor Setup

### macOS

```bash
brew install tor
brew services start tor
```

### Linux (Debian/Ubuntu)

```bash
sudo apt install tor
sudo systemctl start tor
```

### Docker

```bash
docker run -d -p 9050:9050 dperson/torproxy
```

Tor runs on port 9050 by default.

## Configuration

Add to your `config/config.exs`:

```elixir
config :torex,
  tor_host: ~c"127.0.0.1",
  tor_port: 9050
```

Note: `tor_host` uses a charlist (`~c"..."`) as required by the underlying `:hackney` library.

## Usage

### GET requests

```elixir
{:ok, body} = Torex.get("http://example.onion")

case Torex.get("http://check.torproject.org") do
  {:ok, body} ->
    IO.puts("Response: #{body}")
  {:error, {:http_error, status, body}} ->
    IO.puts("HTTP #{status}: #{body}")
  {:error, %{reason: reason}} ->
    IO.puts("Request failed: #{reason}")
end
```

### POST requests

POST requests automatically encode the body as JSON:

```elixir
{:ok, response} = Torex.post("http://example.onion/api", %{
  username: "user",
  password: "secret"
})
```

### Error Handling

Torex returns tagged tuples for all responses:

```elixir
case Torex.get(url) do
  {:ok, body} ->
    # Success - HTTP 200
    process(body)

  {:error, {:http_error, status_code, body}} ->
    # Non-200 HTTP response
    Logger.warning("HTTP #{status_code}: #{body}")

  {:error, %{reason: :econnrefused}} ->
    # Tor not running or unreachable
    Logger.error("Cannot connect to Tor")

  {:error, %{reason: :timeout}} ->
    # Request timed out
    Logger.error("Request timed out")

  {:error, error} ->
    # Other errors
    Logger.error("Request failed: #{inspect(error)}")
end
```

## Verifying Tor Connection

Test that your traffic is routing through Tor:

```elixir
{:ok, body} = Torex.get("https://check.torproject.org/api/ip")
IO.inspect(Jason.decode!(body))
# => %{"IsTor" => true, "IP" => "..."}
```

## License

MIT
