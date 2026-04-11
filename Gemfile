source "https://rubygems.org"

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# Auth
gem "devise"
gem "devise-jwt"
gem "bcrypt", "~> 3.1.7"

# Authorization
gem "pundit"

# Audit
gem "paper_trail"

# Serializers
gem "blueprinter"

# Background jobs
gem "sidekiq", "~> 8.1"
gem "redis", "~> 5.0"

# CORS + Rate limiting
gem "rack-cors"
gem "rack-attack"

# File storage
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 1.2"

# Monitoring
gem "lograge"
gem "sentry-ruby"
gem "sentry-rails"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "bundler-audit", require: false
end

group :test do
  gem "database_cleaner-active_record"
end
