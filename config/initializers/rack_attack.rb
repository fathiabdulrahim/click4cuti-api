class Rack::Attack
  # Throttle auth endpoints: 5 attempts per minute per IP
  throttle("auth/ip", limit: 5, period: 1.minute) do |req|
    if req.path.match?(%r{^/api/v1/(admin/)?auth/sign_in}) && req.post?
      req.ip
    end
  end

  # Throttle password reset: 5 attempts per minute per IP
  throttle("password_reset/ip", limit: 5, period: 1.minute) do |req|
    if req.path.match?(%r{^/api/v1/(admin/)?auth/password}) && req.post?
      req.ip
    end
  end

  # Global API throttle: 300 requests per 5 minutes per IP
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Too Many Requests", message: "Rate limit exceeded. Please try again later." }.to_json]
    ]
  end
end
