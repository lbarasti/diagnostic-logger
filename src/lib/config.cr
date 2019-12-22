require "yaml"
require "logger"
require "./appenders"

class DiagnosticLogger
  module YamlSeverityConverter
    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Logger::Severity
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end
  
      Logger::Severity.parse(node.value)
    end
  end

  module YamlAppenderConverter
    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end
  
      Config::Appender.parse(node.value)
    end
  end

  record Config,
    level : ::Logger::Severity,
    batch_size : Int32,
    batch_max_time : Time::Span,
    appender : IO,
    pattern : String

  struct Config
    ConfigFile = "config.yml" # point at top-level configuration file
    
    DefaultLevel = ::Logger::Severity::INFO
    DefaultBatchSize = 1
    DefaultBatchMaxTime = 0_f32
    DefaultAppender = ConsoleAppender.new(1, blocking: (LibC.isatty(1)) == 0)
    DefaultPattern = "%{date} | [%{level}] %{pid}>%{fiber}>%{logger} | %{msg}"

    enum Appender
      ConsoleAppender,
      FileAppender
    end

    private record RawConfig,
      level : ::Logger::Severity,
      batch_size : Int32,
      batch_max_time : Float32,
      appender_class : Appender,
      pattern : String
  
    struct RawConfig
      YAML.mapping(
        level: {
          type: Logger::Severity,
          default: DefaultLevel,
          converter: YamlSeverityConverter
        },
        batch_size: {
          type: Int32,
          default: DefaultBatchSize
        },
        batch_max_time: {
          type: Float32,
          default: DefaultBatchMaxTime
        },
        appender_class: {
          type: Appender,
          default: Appender::ConsoleAppender,
          converter: YamlAppenderConverter
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
        batch_max_time: raw_config.batch_max_time.seconds,
        appender: appender,
        pattern: raw_config.pattern
      )
    end
  end
end
