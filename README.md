# Torex

Very simple connector to TOR network. Basically this is HTTPoison client with proxy on Tor node.

Before running this project you need to have tor node running.
To install tor node for macos run this:

    brew install tor
    brew services start tor

You'll have tor running on your machine where you can connect on PORT=9050

## Usage

When Tor is up and running add to your app config the following

    config :torex,
      :tor_server,
        ip: '127.0.0.1', # note charlist here, not binary
        port: 9050

Make requests:

    {:ok, contents} = Torex.get(url)
    {:ok, result}   = Torex.post(url, params)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `torex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:torex, "~> 0.1.0"}]
end
```

## Contribution

1. Fork it
2. Create feature/bugfix branch
3. Code/fix
4. Commit and push
5. Create Pull Request

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/torex](https://hexdocs.pm/torex).
