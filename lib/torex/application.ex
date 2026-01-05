defmodule Torex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = :hackney_pool.start_pool(:torex_pool, timeout: 60_000, max_connections: 1_000)

    children = []

    opts = [strategy: :one_for_one, name: Torex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :hackney_pool.stop_pool(:torex_pool)
  end
end
