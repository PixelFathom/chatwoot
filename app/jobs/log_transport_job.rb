class LogTransportJob < ApplicationJob
  queue_as :low

  def perform(hours = 24, max_size_mb = 10)
    Rails.logger.info "Starting log transport for #{hours}h, max #{max_size_mb}MB"

    service = LogTransportService.new(hours: hours, max_size_mb: max_size_mb)
    logs_data = service.collect_and_format_logs

    if logs_data[:logs].empty?
      Rails.logger.info "No logs to transport"
      return
    end

    ChatwootHub.transport_logs(logs_data)
    Rails.logger.info "Log transport completed: #{logs_data[:logs].size} entries"
  end
end