if defined?(MissionControl)
  Rails.application.config.to_prepare do
    MissionControl::Jobs::ApplicationController.before_action do
      # Only allow requests to mission control from the trusted IP (and localhost).
      if !request.local? && request.remote_ip != Rails.application.config.x.trusted_ip
        render plain: "Unauthorized", status: :unauthorized
      end
    end
  end
end
