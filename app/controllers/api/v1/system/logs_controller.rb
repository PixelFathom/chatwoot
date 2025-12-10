class Api::V1::System::LogsController < Api::BaseController
  before_action :ensure_super_admin

  def export
    return render_not_enabled unless log_transport_enabled?

    hours = params[:hours]&.to_i || 24
    max_size_mb = params[:max_size_mb]&.to_i || 10

    # Validate limits
    hours = [hours, 168].min # Max 7 days
    max_size_mb = [max_size_mb, 50].min # Max 50MB

    job_id = LogTransportJob.perform_later(hours, max_size_mb).job_id

    render json: {
      status: 'accepted',
      job_id: job_id,
      message: "Log export queued for last #{hours} hours"
    }, status: :accepted
  end

  private

  def ensure_super_admin
    return if current_user&.is_a?(SuperAdmin)

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def log_transport_enabled?
    ENV.fetch('LOG_TRANSPORT_ENABLED', 'false') == 'true'
  end

  def render_not_enabled
    render json: {
      error: 'Log transport not enabled',
      message: 'Set LOG_TRANSPORT_ENABLED=true to enable this feature'
    }, status: :forbidden
  end
end