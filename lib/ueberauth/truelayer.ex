defmodule Ueberauth.Strategy.TrueLayer do
  @moduledoc """
  Truelayer Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "accounts balance cards direct_debits info offline_access standing_orders transactions",
    default_providers: "uk-ob-all uk-oauth-all",
    uid_field: :id,
    response_type: "code",
    ignores_csrf_attack: true

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Truelayer authentication.
  """
  def handle_request!(conn) do
    opts = oauth_client_options_from_conn(conn)

    params =
      conn.params
      |> maybe_replace_param(conn, "response_type", :response_type)
      |> maybe_replace_param(conn, "scope", :default_scope)
      |> maybe_replace_param(conn, "providers", :default_providers)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.put(:redirect_uri, callback_url(conn))

    redirect!(conn, Ueberauth.Strategy.TrueLayer.OAuth.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Truelayer.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = oauth_client_options_from_conn(conn)

    try do
      client = Ueberauth.Strategy.TrueLayer.OAuth.get_token!([code: code], opts)
      put_private(conn, :truelayer_token, client.token)
    rescue
      e -> set_errors!(conn, [error("get_token_error", e)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:truelayer_token, nil)
    |> put_private(:truelayer_refresh_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(_conn) do
    nil
  end

  @doc """
  Includes the credentials from the Truelayer response.
  """
  def credentials(conn) do
    token = conn.private.truelayer_token
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token,
      refresh_token: token.refresh_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the
  `Ueberauth.Auth` struct.
  """
  def info(_conn) do
    %Info{}
  end

  @doc """
  Stores the raw information (including the token) obtained from
  the Truelayer callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.truelayer_token,
      }
    }
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end

  defp option(nil, conn, key), do: option(conn, key)
  defp option(value, _conn, _key), do: value

  defp maybe_replace_param(params, conn, name, config_key) do
    if params[name] || is_nil(option(params[name], conn, config_key)) do
      params
    else
      Map.put(
        params,
        name,
        option(params[name], conn, config_key)
      )
    end
  end

  defp oauth_client_options_from_conn(conn) do
    base_options = [redirect_uri: callback_url(conn)]
    request_options = conn.private[:ueberauth_request_options].options

    case {request_options[:client_id], request_options[:client_secret]} do
      {nil, _} -> base_options
      {_, nil} -> base_options
      {id, secret} -> [client_id: id, client_secret: secret] ++ base_options
    end
  end
end
