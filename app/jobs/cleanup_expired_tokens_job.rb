class CleanupExpiredTokensJob < ApplicationJob
  queue_as :low

  def perform
    deleted = JwtDenylist.where("exp < ?", Time.current).delete_all
    Rails.logger.info "CleanupExpiredTokensJob: removed #{deleted} expired tokens"
  end
end
