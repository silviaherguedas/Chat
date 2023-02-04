import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chat, ChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kf97Y8D7VYh1Lsi7e0ttZX9TEqgwr+uZSoe+HaMrSlSrXv3ZN+ZLdUkwbzjqZ9Uo",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
