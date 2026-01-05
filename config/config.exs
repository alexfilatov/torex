import Config

config :torex,
  tor_host: ~c"127.0.0.1",
  tor_port: 9050

import_config "#{config_env()}.exs"
