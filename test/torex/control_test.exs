defmodule Torex.ControlTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  describe "renew_circuit/0" do
    test "successfully renews circuit" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:ok, :fake_socket}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "AUTHENTICATE\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "SIGNAL NEWNYM\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:close, fn :fake_socket ->
        :ok
      end)

      assert :ok = Torex.Control.renew_circuit()
    end

    test "successfully renews circuit with password authentication" do
      Application.put_env(:torex, :control_password, "test_password")

      on_exit(fn -> Application.delete_env(:torex, :control_password) end)

      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:ok, :fake_socket}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "AUTHENTICATE \"test_password\"\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "SIGNAL NEWNYM\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:close, fn :fake_socket ->
        :ok
      end)

      assert :ok = Torex.Control.renew_circuit()
    end

    test "returns error when control port is unavailable" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:error, :econnrefused}
      end)

      assert {:error, :control_port_unavailable} = Torex.Control.renew_circuit()
    end

    test "returns error on authentication failure" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:ok, :fake_socket}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "AUTHENTICATE\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "515 Authentication failed\r\n"}
      end)

      assert {:error, :authentication_failed} = Torex.Control.renew_circuit()
    end

    test "returns error on signal failure" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:ok, :fake_socket}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "AUTHENTICATE\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "SIGNAL NEWNYM\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "552 Unknown signal\r\n"}
      end)

      assert {:error, {:signal_error, "552 Unknown signal"}} = Torex.Control.renew_circuit()
    end
  end

  describe "get_info/1" do
    test "successfully gets version info" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:ok, :fake_socket}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "AUTHENTICATE\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:send, fn :fake_socket, "GETINFO version\r\n" ->
        :ok
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250-version=0.4.8.12\r\n"}
      end)
      |> expect(:recv, fn :fake_socket, 0, _timeout ->
        {:ok, "250 OK\r\n"}
      end)
      |> expect(:close, fn :fake_socket ->
        :ok
      end)

      assert {:ok, "0.4.8.12"} = Torex.Control.get_info("version")
    end

    test "returns error when control port is unavailable" do
      Torex.MockTCPClient
      |> expect(:connect, fn ~c"127.0.0.1", 9051, _opts, _timeout ->
        {:error, :econnrefused}
      end)

      assert {:error, :control_port_unavailable} = Torex.Control.get_info("version")
    end
  end
end
