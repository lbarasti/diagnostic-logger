require "./spec_helper"

alias Config = DiagnosticLogger::Config
describe Config do
  it "will load a default config when an empty one is passed" do
    c = Config.load("logger:\n")
    c.level.should eq Logger::Severity::INFO
    c.batch_size.should eq 1
    c.batch_max_time.should eq 0.seconds
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
end
