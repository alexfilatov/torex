defmodule Torex.HTTPClient do
  @moduledoc false

  @callback request(
              method :: atom(),
              url :: binary(),
              body :: binary(),
              headers :: list(),
              options :: keyword()
            ) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}

  use HTTPoison.Base
end
