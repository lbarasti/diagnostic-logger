require "logger"
require "./lib/version"
require "./lib/config"
require "./lib/channel_util"

class DiagnosticLogger
  private alias Message = {timestamp: Time, msg: String, fiber_name: String?, level: ::Logger::Severity, name: String?, pid: Int32}
  private Input = Channel(Message).new
  @@batch_max_size = Config.load_batch_max_size
  @@batch_max_time = Config.load_batch_max_time
  @@batch : Channel(Enumerable(Message)) = ChannelUtil.batch(Input, max_size: @@batch_max_size, max_time: @@batch_max_time)

  spawn do
    loop do
      rec = @@batch.receive
      write(rec)
    end
  end

  def initialize(@name : String? = nil)
  end

  def self.write(messages : Enumerable(Message))
    messages.each { |message|
      io << pattern % {
        date:   message[:timestamp],
        level:  message[:level],
        logger: message[:name],
        fiber:  message[:fiber_name],
        msg:    message[:msg],
        pid:    message[:pid],
      }
      io << "\n"
    }
    io.flush
  end

  def self.io # lazy loading the appender for better testability
    @@io ||= Config.load_appender
  end

  def self.level
    @@level ||= Config.load_level
  end

  def self.pattern
    @@pattern ||= Config.load_pattern
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
        pid:        Process.pid,
      })
    end
  {% end %}
end
