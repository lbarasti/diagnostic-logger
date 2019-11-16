require "logger"
require "./lib/version"
require "./lib/config"

class DiagnosticLogger
  private alias Message = {timestamp: Time, msg: String, fiber_name: String?, level: ::Logger::Severity, name: String?}
  private Input = Channel(Message).new

  spawn do
    loop do
      write(Input.receive)
    end
  end

  def initialize(@name : String? = nil)
  end

  def self.write(message)
    io << "#{message[:timestamp]} " <<
      "[#{message[:level]}] " <<
      "#{message[:name]}:#{message[:fiber_name]}> #{message[:msg]}" <<
      "\n"
    io.flush
  end

  def self.io # lazy loading the appender for better testability
    @@io ||= Config.load_appender
  end

  def self.level
    @@level ||= Config.load_level
  end

  {% for name in ::Logger::Severity.constants %}

    # Logs *message* if the logger's current severity is lower or equal to `{{name.id}}`.
    def {{name.id.downcase}}(message)
      return if Logger::{{name.id}} < {{@type}}.level
      Input.send({
        timestamp:  Time.utc,
        msg:        message,
        fiber_name: Fiber.current.name,
        level:      Logger::{{name.id}},
        name:       @name,
      })
    end
  {% end %}
end
