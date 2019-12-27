require "./spec_helper"

alias Config = DiagnosticLogger::Config
describe Config do
  it "will load a default config when an empty one is passed" do
    c = Config.load("logger:\n")
    c.level.should eq Logger::Severity::INFO
    c.batch_size.should eq 1
    c.batch_interval.should eq 0.seconds
    c.appender.should be_a ConsoleAppender
    c.pattern.should eq Config::DefaultPattern
  end

  it "supports File appenders" do
    appender = Config.load("logger:\n  appender_class: FileAppender\n  appender_file: logs").appender
    appender.should be_a(FileAppender)
  end

  it "supports Console appenders" do
    appender = Config.load("logger:\n  appender_class: ConsoleAppender").appender
    appender.should be_a(ConsoleAppender)
  end

  it "raises an exception if the appender class is unknown" do
    expect_raises(Exception) do
      appender = Config.load("logger:\n  appender_class: UnknownAppender").appender
    end
  end

  it "can load batch settings from config" do
    config = Config.load("logger:\n  batch_size: 400\n  batch_interval: 2.5")
    config.batch_size.should eq(400)
    config.batch_interval.should eq(2.5.seconds)
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
