module AuthHelpers
  def auth_headers_for_user(user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end

  def auth_headers_for_admin(admin_user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(admin_user, :admin_user, nil)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end
