Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "http://localhost:5173",
      "http://localhost:3000",
      /\Ahttps:\/\/.*\.click4cuti\.com\z/,
      ENV.fetch("CORS_ORIGIN_STAGING", "https://staging.click4cuti.com"),
      ENV.fetch("CORS_ORIGIN_PRODUCTION", "https://app.click4cuti.com")
    )

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      credentials: true,
      max_age: 86400
  end
end
