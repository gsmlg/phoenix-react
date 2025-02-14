# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :react_demo,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :react_demo, ReactDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ReactDemoWeb.ErrorHTML, json: ReactDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ReactDemo.PubSub,
  live_view: [signing_salt: "y8Mo2X4Z"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  react_demo: [
    args:
      ~w(js/app.js --bundle --loader:.js=jsx --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  react_demo: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix_react_server, Phoenix.React,
  runtime: Phoenix.React.Runtime.Bun,
  component_base: Path.expand("../assets/component", __DIR__),
  cache_ttl: 60

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
