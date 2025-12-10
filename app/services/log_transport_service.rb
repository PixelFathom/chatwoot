class LogTransportService
  def initialize(hours: 24, max_size_mb: 10)
    @hours = hours
    @max_size_mb = max_size_mb
    @start_time = hours.hours.ago
  end

  def collect_and_format_logs
    logs = collect_recent_logs
    {
      logs: logs,
      metadata: {
        total_lines: logs.size,
        time_range: "#{@hours}h",
        chatwoot_version: Chatwoot.config[:version],
        collected_at: Time.current.iso8601
      }
    }
  end

  private

  def collect_recent_logs
    log_entries = []
    log_file_path = Rails.root.join('log', "#{Rails.env}.log")

    return [] unless File.exist?(log_file_path)

    File.foreach(log_file_path).lazy.reverse_each.take(10000).each do |line|
      entry = parse_log_line(line.strip)
      next unless entry && entry[:timestamp] >= @start_time

      log_entries << entry
      break if log_entries.size >= 5000 # Safety limit
    end

    log_entries.reverse
  end

  def parse_log_line(line)
    # Simple timestamp extraction for Rails logs
    match = line.match(/^[DWIEF], \[(.+?)\]/)
    return nil unless match

    timestamp = Time.parse(match[1]) rescue nil
    return nil unless timestamp

    level = extract_log_level(line)
    message = sanitize_log_message(line)

    {
      timestamp: timestamp.iso8601,
      level: level,
      message: message,
      source: 'rails'
    }
  rescue
    nil
  end

  def extract_log_level(line)
    case line[0]
    when 'D' then 'debug'
    when 'I' then 'info'
    when 'W' then 'warn'
    when 'E' then 'error'
    when 'F' then 'fatal'
    else 'unknown'
    end
  end

  def sanitize_log_message(message)
    # Remove sensitive data patterns
    message.gsub(/password["\s]*[:=]["\s]*[^"\s,}]+/i, 'password=[FILTERED]')
           .gsub(/token["\s]*[:=]["\s]*[^"\s,}]+/i, 'token=[FILTERED]')
           .gsub(/secret["\s]*[:=]["\s]*[^"\s,}]+/i, 'secret=[FILTERED]')
  end
end