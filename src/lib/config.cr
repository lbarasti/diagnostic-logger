require "yaml"
require "logger"
require "./appenders"

class DiagnosticLogger
  ConfigNamespace = "logger"
  DefaultLevel    = ::Logger::Severity::INFO
  DefaultAppender = ConsoleAppender.new(1, blocking: (LibC.isatty(1)) == 0)
  DefaultPattern  = "%{date} | [%{level}] %{pid}>%{fiber}>%{logger} | %{msg}"

  record Config,
    level : ::Logger::Severity,
    batch_config : BatchConfig?,
    appender : IO,
    pattern : String do
    enum AppenderClass
      ConsoleAppender
      FileAppender
    end

    private module YamlToTimeSpan
      def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Time::Span
        unless node.is_a?(YAML::Nodes::Scalar)
          node.raise "Expected scalar, not #{node.class}"
        end

        (node.value.to_f? || node.value.to_i).seconds
      end
    end

    private abstract class YamlToAppender
      def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
        appender_config = Hash(String, String).new(ctx, node)
        case AppenderClass.parse(appender_config["class"])
        when AppenderClass::FileAppender
          path_to_file = appender_config["file"]
          FileAppender.new(path_to_file, "a")
        when AppenderClass::ConsoleAppender
          DefaultAppender
        end.not_nil!
      end
    end

    private record BatchConfig, size : Int32, interval : Time::Span do
      YAML.mapping(
        size: Int32,
        interval: {
          type:      Time::Span,
          converter: YamlToTimeSpan,
        }
      )

      def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : BatchConfig
        BatchConfig.new(ctx, node)
      end
    end

    YAML.mapping(
      level: {
        type:    Logger::Severity,
        default: DefaultLevel,
      },
      batch_config: {
        key:       "batch",
        type:      BatchConfig?,
        default:   nil,
        converter: BatchConfig,
      },
      appender: {
        type:      IO,
        default:   DefaultAppender,
        converter: YamlToAppender,
      },
      pattern: {
        type:    String,
        default: DefaultPattern,
      }
    )

    def self.load(config : String | IO) : Config
      yml = YAML.parse config
      logger_yml = yml.raw.nil? ? "" : yml[ConfigNamespace]?.to_yaml
      Config.from_yaml(logger_yml)
    end
  end
end
