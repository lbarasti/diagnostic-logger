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

    def self.load_batch_max_size(config : String = File.read(ConfigFile)) : Int32
      data = YAML.parse config
      batch_config = data["logger"]["batch"]?
      batch_config && batch_config["max_size"]? ? batch_config["max_size"].as_i : 1
    end

    def self.load_batch_max_time(config : String = File.read(ConfigFile)) : Time::Span
      data = YAML.parse config
      batch_config = data["logger"]["batch"]?
      max_time = batch_config && batch_config["max_time"]? ? batch_config["max_time"].as_f : 0.5
      max_time.seconds
    end
  end
end
