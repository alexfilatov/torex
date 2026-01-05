defmodule TorexTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  describe "get/1" do
    test "returns body on successful response" do
      expect(Torex.MockHTTPClient, :request, fn :get, url, "", [], opts ->
        assert url == "http://example.onion"
        assert {:socks5, ~c"127.0.0.1", 9050} == opts[:hackney][:proxy]
        {:ok, %HTTPoison.Response{status_code: 200, body: "<html>test</html>"}}
      end)

      assert {:ok, "<html>test</html>"} = Torex.get("http://example.onion")
    end

    test "returns error tuple on non-200 status" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], _opts ->
        {:ok, %HTTPoison.Response{status_code: 404, body: "Not Found"}}
      end)

      assert {:error, {:http_error, 404, "Not Found"}} = Torex.get("http://example.onion")
    end

    test "returns error tuple on 500 status" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], _opts ->
        {:ok, %HTTPoison.Response{status_code: 500, body: "Internal Server Error"}}
      end)

      assert {:error, {:http_error, 500, "Internal Server Error"}} = Torex.get("http://example.onion")
    end

    test "returns error on connection refused" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], _opts ->
        {:error, %HTTPoison.Error{reason: :econnrefused}}
      end)

      assert {:error, %HTTPoison.Error{reason: :econnrefused}} = Torex.get("http://example.onion")
    end

    test "returns error on timeout" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], _opts ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      assert {:error, %HTTPoison.Error{reason: :timeout}} = Torex.get("http://example.onion")
    end

    test "returns error on connection closed" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], _opts ->
        {:error, %HTTPoison.Error{reason: :closed}}
      end)

      assert {:error, %HTTPoison.Error{reason: :closed}} = Torex.get("http://example.onion")
    end
  end

  describe "post/2" do
    test "returns body on successful response" do
      expect(Torex.MockHTTPClient, :request, fn :post, url, body, headers, opts ->
        assert url == "http://example.onion/api"
        assert body == ~s({"key":"value"})
        assert {"content-type", "application/json"} in headers
        assert {:socks5, ~c"127.0.0.1", 9050} == opts[:hackney][:proxy]
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s({"result":"ok"})}}
      end)

      assert {:ok, ~s({"result":"ok"})} = Torex.post("http://example.onion/api", %{key: "value"})
    end

    test "encodes complex nested params as JSON" do
      expect(Torex.MockHTTPClient, :request, fn :post, _url, body, _headers, _opts ->
        decoded = Jason.decode!(body)
        assert decoded == %{"user" => %{"name" => "test", "tags" => ["a", "b"]}}
        {:ok, %HTTPoison.Response{status_code: 200, body: "ok"}}
      end)

      assert {:ok, "ok"} = Torex.post("http://example.onion", %{user: %{name: "test", tags: ["a", "b"]}})
    end

    test "returns error tuple on non-200 status" do
      expect(Torex.MockHTTPClient, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok, %HTTPoison.Response{status_code: 422, body: ~s({"error":"invalid"})}}
      end)

      assert {:error, {:http_error, 422, ~s({"error":"invalid"})}} =
               Torex.post("http://example.onion", %{})
    end

    test "returns error on connection refused" do
      expect(Torex.MockHTTPClient, :request, fn :post, _url, _body, _headers, _opts ->
        {:error, %HTTPoison.Error{reason: :econnrefused}}
      end)

      assert {:error, %HTTPoison.Error{reason: :econnrefused}} =
               Torex.post("http://example.onion", %{})
    end
  end

  describe "proxy configuration" do
    test "uses configured proxy settings" do
      expect(Torex.MockHTTPClient, :request, fn :get, _url, "", [], opts ->
        hackney_opts = opts[:hackney]
        assert :insecure in hackney_opts
        assert hackney_opts[:pool] == :torex_pool
        assert hackney_opts[:proxy] == {:socks5, ~c"127.0.0.1", 9050}
        {:ok, %HTTPoison.Response{status_code: 200, body: "ok"}}
      end)

      Torex.get("http://example.onion")
    end
  end
end
