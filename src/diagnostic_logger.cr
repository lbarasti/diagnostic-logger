require "logger"
require "./lib/version"
require "./lib/config"
require "./lib/channel_util"

class DiagnosticLogger
  private alias Message = {timestamp: Time, msg: String, fiber_name: String?, level: ::Logger::Severity, name: String?, pid: Int32}
  private Input = Channel(Message).new
  @@config : Config = Config.load

  @@batch_interval : Time::Span = @@config.batch_interval
  @@batch : Channel(Enumerable(Message)) | Channel(Message) = if @@config.flush_immediately?
    Input
  else
    ChannelUtil.batch(Input, size: @@config.batch_size, interval: @@batch_interval)
  end

  spawn do
    loop do
      rec = @@batch.receive
      write(rec)
    end
  end

  def initialize(@name : String? = nil, @level : Logger::Severity = @@config.level)
  end

  def self.write(messages : Enumerable(Message))
    messages.each { |message|
      write_one(message)
    }
    io.flush
  end

  def self.write(message : Message)
    write_one(message)
    io.flush
  end

  def self.write_one(message : Message)
    io << pattern % {
      date:   message[:timestamp],
      level:  message[:level],
      logger: message[:name],
      fiber:  message[:fiber_name],
      msg:    message[:msg],
      pid:    message[:pid],
    }
    io << "\n"
  end

  def self.io
    @@config.appender
  end

  def self.pattern
    @@config.pattern
  end

  {% for name in ::Logger::Severity.constants %}

    # Logs *message* if the logger's current severity is lower or equal to `{{name.id}}`.
    def {{name.id.downcase}}(message)
      return if Logger::{{name.id}} < @level
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
