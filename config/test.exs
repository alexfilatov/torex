import Config

config :torex,
  http_client: Torex.MockHTTPClient,
  tcp_client: Torex.MockTCPClient
