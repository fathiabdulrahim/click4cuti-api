require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Click4cutiApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # Only loads a smaller set of middleware suitable for API only apps.
    config.api_only = true

    # UUID primary keys via pgcrypto
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Timezone
    config.time_zone = "Kuala Lumpur"
    config.active_record.default_timezone = :utc

    # Active Job backend
    config.active_job.queue_adapter = :sidekiq

    # Lograge
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = lambda do |event|
      {
        time: Time.current.iso8601,
        host: event.payload[:host],
        remote_ip: event.payload[:remote_ip],
        user_agent: event.payload[:user_agent]
      }
    end

    # Middleware
    config.middleware.use Rack::Cors
    config.middleware.use Rack::Attack

    # Autoload serializers/blueprints
    config.autoload_paths << Rails.root.join("app/serializers")
    config.autoload_paths << Rails.root.join("app/services")
    config.autoload_paths << Rails.root.join("app/policies")
  end
end
