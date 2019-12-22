require "logger"
require "./lib/version"
require "./lib/config"
require "./lib/channel_util"

class DiagnosticLogger
  private alias Message = {timestamp: Time, msg: String, fiber_name: String?, level: ::Logger::Severity, name: String?, pid: Int32}
  private Input = Channel(Message).new
  @@config : Config = Config.load
  @@batch_max_size : Int32 = @@config.batch_size
  @@batch_max_time : Time::Span = @@config.batch_max_time
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

  def self.io
    @@config.appender
  end

  def self.level
    @@config.level
  end

  def self.pattern
    @@config.pattern
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
