require "yaml"
require "logger"
require "./appenders"

class DiagnosticLogger
  module Config
    class UnknownAppender < Exception
      def initialize(clazz)
        super("Unknown logger.appender.class #{clazz}")
      end
    end

    DefaultPattern = "%{date} [%{level}] %{logger}:%{fiber}> %{msg}"

    ConfigFile = "config.yml" # point at top-level configuration file
    def self.load_appender(config : String = File.read(ConfigFile))
      data = YAML.parse config
      appender = data["logger"]["appender"]
      case appender["class"].as_s
      when "FileAppender"
        log_filepath = appender["file"].as_s
        FileAppender.new(log_filepath, "a")
      when "ConsoleAppender"
        ConsoleAppender.new(1, blocking: (LibC.isatty(1)) == 0)
      else raise UnknownAppender.new(appender["class"])
      end
    end

    def self.load_level(config : String = File.read(ConfigFile))
      data = YAML.parse config
      Logger::Severity.parse(data["logger"]["level"].as_s)
    end

    def self.load_pattern(config : String = File.read(ConfigFile))
      data = YAML.parse config
      appender = data["logger"]["appender"]?
      appender && appender["pattern"]? ? appender["pattern"].as_s : DefaultPattern
    end
  end
end
