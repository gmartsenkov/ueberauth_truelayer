# UeberauthTruelayer

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ueberauth_truelayer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_truelayer, "~> 0.1.0"}
  ]
end
```

## Usage
Example setup for Truelayer's test environment

```elixir
config :ueberauth, Ueberauth.Strategy.TrueLayer.OAuth,
  client_id: "client_id",
  client_secret: "client_secret",
  site: "https://api.truelayer-sandbox.com",
  authorize_url: "https://auth.truelayer-sandbox.com",
  token_url: "https://auth.truelayer-sandbox.com/connect/token"

config :ueberauth, Ueberauth,
  base_path: "/",
  providers: [
    truelayer: {Ueberauth.Strategy.TrueLayer, [
      default_providers: "uk-cs-mock uk-ob-all uk-oauth-all"
    ]}
  ]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ueberauth_truelayer>.

