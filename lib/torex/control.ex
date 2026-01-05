defmodule Torex.Control do
  @moduledoc """
  Tor control protocol client for managing Tor circuits.

  Connects to the Tor control port to send commands like NEWNYM
  (request new circuit/exit node IP).

  ## Configuration

      config :torex,
        control_port: 9051,
        control_password: "your_password"  # optional if using cookie auth

  ## Tor Configuration

  To enable the control port, add to your `torrc`:

      ControlPort 9051
      HashedControlPassword <your_hashed_password>

  Generate a hashed password with:

      tor --hash-password "your_password"
  """

  require Logger

  @newnym_signal "NEWNYM"
  @rate_limit_seconds 10
  @tcp_opts [:binary, active: false, packet: :line]
  @timeout 5000

  @doc """
  Requests a new Tor circuit (new exit node IP).

  Returns `:ok` on success, `{:error, reason}` on failure.

  Note: Tor rate-limits NEWNYM to once per #{@rate_limit_seconds} seconds.
  Calling more frequently will succeed but won't change the circuit.

  ## Examples

      iex> Torex.Control.renew_circuit()
      :ok

      iex> Torex.Control.renew_circuit()
      {:error, :authentication_failed}
  """
  @spec renew_circuit() :: :ok | {:error, atom() | String.t()}
  def renew_circuit do
    with {:ok, socket} <- connect(),
         :ok <- authenticate(socket),
         :ok <- send_signal(socket, @newnym_signal),
         :ok <- tcp_client().close(socket) do
      Logger.debug("Tor circuit renewed successfully")
      :ok
    else
      {:error, reason} = error ->
        Logger.error("Failed to renew Tor circuit: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Gets information from the Tor control port.

  ## Examples

      iex> Torex.Control.get_info("version")
      {:ok, "0.4.8.12"}

      iex> Torex.Control.get_info("circuit-status")
      {:ok, "..."}
  """
  @spec get_info(String.t()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def get_info(key) do
    with {:ok, socket} <- connect(),
         :ok <- authenticate(socket),
         {:ok, value} <- send_getinfo(socket, key),
         :ok <- tcp_client().close(socket) do
      {:ok, value}
    end
  end

  defp connect do
    host = control_host()
    port = control_port()

    case tcp_client().connect(host, port, @tcp_opts, @timeout) do
      {:ok, socket} ->
        # Read the welcome message
        case tcp_client().recv(socket, 0, @timeout) do
          {:ok, <<"250 ", _rest::binary>>} -> {:ok, socket}
          {:ok, <<"220 ", _rest::binary>>} -> {:ok, socket}
          {:ok, other} -> {:error, {:unexpected_response, other}}
          {:error, reason} -> {:error, reason}
        end

      {:error, :econnrefused} ->
        {:error, :control_port_unavailable}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authenticate(socket) do
    password = control_password()

    command =
      if password do
        "AUTHENTICATE \"#{password}\"\r\n"
      else
        "AUTHENTICATE\r\n"
      end

    :ok = tcp_client().send(socket, command)

    case tcp_client().recv(socket, 0, @timeout) do
      {:ok, <<"250 OK", _rest::binary>>} ->
        :ok

      {:ok, <<"515", _rest::binary>>} ->
        {:error, :authentication_failed}

      {:ok, other} ->
        {:error, {:authentication_error, String.trim(other)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_signal(socket, signal) do
    :ok = tcp_client().send(socket, "SIGNAL #{signal}\r\n")

    case tcp_client().recv(socket, 0, @timeout) do
      {:ok, <<"250 OK", _rest::binary>>} ->
        :ok

      {:ok, other} ->
        {:error, {:signal_error, String.trim(other)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_getinfo(socket, key) do
    :ok = tcp_client().send(socket, "GETINFO #{key}\r\n")

    case tcp_client().recv(socket, 0, @timeout) do
      {:ok, <<"250-", rest::binary>>} ->
        # Read the closing 250 OK
        tcp_client().recv(socket, 0, @timeout)
        value = String.replace_prefix(rest, "#{key}=", "")
        {:ok, String.trim(value)}

      {:ok, <<"250 OK", _rest::binary>>} ->
        {:ok, ""}

      {:ok, other} ->
        {:error, {:getinfo_error, String.trim(other)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp tcp_client do
    Application.get_env(:torex, :tcp_client, Torex.TCPClient)
  end

  defp control_host do
    Application.get_env(:torex, :control_host, ~c"127.0.0.1")
  end

  defp control_port do
    Application.get_env(:torex, :control_port, 9051)
  end

  defp control_password do
    Application.get_env(:torex, :control_password)
  end
end
