defmodule Torex.TCPClient do
  @moduledoc false

  @callback connect(host :: charlist(), port :: integer(), opts :: list(), timeout :: integer()) ::
              {:ok, port()} | {:error, term()}
  @callback send(socket :: port(), data :: iodata()) :: :ok | {:error, term()}
  @callback recv(socket :: port(), length :: integer(), timeout :: integer()) ::
              {:ok, binary()} | {:error, term()}
  @callback close(socket :: port()) :: :ok

  def connect(host, port, opts, timeout) do
    :gen_tcp.connect(host, port, opts, timeout)
  end

  def send(socket, data) do
    :gen_tcp.send(socket, data)
  end

  def recv(socket, length, timeout) do
    :gen_tcp.recv(socket, length, timeout)
  end

  def close(socket) do
    :gen_tcp.close(socket)
  end
end
