import Config

config :bb,
  respawn_threshold: 5_000,
  size: 5,
  wall_probability: 0.1

config :logger, :console,
  logger: :console,
  format: "$time [$level] $metadata$message\n"

import_config "#{config_env()}.exs"
