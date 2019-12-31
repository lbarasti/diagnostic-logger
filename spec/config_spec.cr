require "./spec_helper"

alias Config = DiagnosticLogger::Config
describe Config do
  it "will load a default config when an empty one is passed" do
    c = Config.load("")
    c.level.should eq Logger::Severity::INFO
    c.batch_config.should be_nil
    c.appender.should be_a DiagnosticLogger::ConsoleAppender
    c.pattern.should eq DiagnosticLogger::DefaultPattern
  end

  it "will load a default config when the namespace is present but empty" do
    c = Config.load("logger:\n")
    c.level.should eq Logger::Severity::INFO
    c.batch_config.should be_nil
    c.appender.should be_a DiagnosticLogger::ConsoleAppender
    c.pattern.should eq DiagnosticLogger::DefaultPattern
  end

  it "supports File appenders" do
    appender = Config.load("logger:\n  appender:\n    class: FileAppender\n    file: logs").appender
    appender.should be_a DiagnosticLogger::FileAppender
  end

  it "supports Console appenders" do
    appender = Config.load("logger:\n  appender:\n    class: ConsoleAppender").appender
    appender.should be_a DiagnosticLogger::ConsoleAppender
  end

  it "raises an exception if the appender class is unknown" do
    expect_raises(Exception) do
      appender = Config.load("logger:\n  appender:\n    class: UnknownAppender").appender
    end
  end

  it "can load batch settings from config" do
    config = Config.load("logger:\n  batch:\n    size: 400\n    interval: 2.5")
    config.batch_config.not_nil!.size.should eq 400
    config.batch_config.not_nil!.interval.should eq 2.5.seconds
  end

  it "can load severity settings from config" do
    config = Config.load("logger:\n  level: WARN")
    config.level.should eq Logger::Severity::WARN
  end

  it "can load the appender's pattern from config" do
    config = Config.load("logger:\n  pattern: \"<%{logger}|%{level}>\"")
    config.pattern.should eq "<%{logger}|%{level}>"
  end
end
