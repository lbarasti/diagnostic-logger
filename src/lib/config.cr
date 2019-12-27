require "yaml"
require "logger"
require "./appenders"

class DiagnosticLogger
  record Config,
    level : ::Logger::Severity,
    batch_size : Int32,
    batch_interval : Time::Span,
    appender : IO,
    pattern : String do

    ConfigFile = "config.yml" # point at top-level configuration file
    
    DefaultLevel = ::Logger::Severity::INFO
    DefaultBatchSize = 1
    DefaultBatchMaxTime = 0_f32
    DefaultAppender = ConsoleAppender.new(1, blocking: (LibC.isatty(1)) == 0)
    DefaultPattern = "%{date} | [%{level}] %{pid}>%{fiber}>%{logger} | %{msg}"

    def flush_immediately? : Bool
      batch_size == 1
    end

    enum Appender
      ConsoleAppender,
      FileAppender
    end

    private record RawConfig,
      level : ::Logger::Severity,
      batch_size : Int32,
      batch_interval : Float32,
      appender_class : Appender,
      pattern : String do
  
      YAML.mapping(
        level: {
          type: Logger::Severity,
          default: DefaultLevel
        },
        batch_size: {
          type: Int32,
          default: DefaultBatchSize
        },
        batch_interval: {
          type: Float32 | Int32,
          default: DefaultBatchMaxTime
        },
        appender_class: {
          type: Appender,
          default: Appender::ConsoleAppender
        },
        pattern: {
          type: String,
          default: DefaultPattern
        }
      )
    end

    def self.load(config : String = File.read(ConfigFile)) : Config
      data = YAML.parse config
      raw_config = RawConfig.from_yaml(data["logger"]? ? data["logger"]?.to_yaml : "")
      
      appender = case raw_config.appender_class
        when Appender::FileAppender
          log_filepath = data.dig?("logger", "appender_file").not_nil!.to_s
          FileAppender.new(log_filepath, "a")
        when Appender::ConsoleAppender
          ConsoleAppender.new(1, blocking: (LibC.isatty(1)) == 0)
      end.not_nil!

      Config.new(
        level: raw_config.level,
        batch_size: raw_config.batch_size,
        batch_interval: raw_config.batch_interval.seconds,
        appender: appender,
        pattern: raw_config.pattern
      )
    end
  end
end
