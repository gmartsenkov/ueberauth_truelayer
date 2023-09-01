defmodule Ueberauth.Strategy.TrueLayer.OAuth do
  @moduledoc """
  OAuth2 for Truelayer.

  Add `:client_id` and `:client_secret` to your configuration:
      config :ueberauth, Ueberauth.Strategy.TrueLayer.OAuth,
        client_id: System.get_env("TRUELAYER_CLIENT_ID"),
        client_secret: System.get_env("TRUELAYER_CLIENT_SECRET")

  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    client_id: "id",
    client_secret: "secret",
    authorize_url: "https://auth.truelayer.com",
    token_url: "https://auth.truelayer.com/connect/token",
    token_method: :post
  ]

  @doc """
  Construct a client for requests to Truelayer.

  This will be setup automatically for you in `Ueberauth.Strategy.Truelayer`.
  These options are only useful for usage outside the normal callback phase
  of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.TrueLayer.OAuth, [])

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.get_token!(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
