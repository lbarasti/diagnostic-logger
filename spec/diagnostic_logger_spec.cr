require "./spec_helper"

TestIO = IO::Memory.new

class DiagnosticLogger
  # override the default appender
  def self.io
    TestIO
  end

  def self.pattern
    "%{date} [%{level}]-[%{logger}--%{fiber}]: %{msg}"
  end
end

describe DiagnosticLogger do
  it "has a version" do
    DiagnosticLogger::VERSION.should eq("0.1.0")
  end

  it "can be initialized" do
    DiagnosticLogger.new
  end

  it "logs a given message" do
    DiagnosticLogger.new("test-1").info("hello world")
    Fiber.yield
    TestIO.to_s.should contain("hello world")
    TestIO.clear
  end

  it "includes info like severity, fiber name and logger name" do
    DiagnosticLogger.new("test-1").info("hello world")
    Fiber.yield
    TestIO.to_s.should contain("INFO")
    TestIO.to_s.should contain("test-1")
    TestIO.to_s.should contain("main")
    TestIO.clear
  end

  it "won't log messages at lower severity than the configured level" do
    DiagnosticLogger.new("test-1").debug("hello world")
    Fiber.yield
    TestIO.to_s.should eq("")
    TestIO.clear
  end

  it "supports custom formatters" do
    DiagnosticLogger.new("test-1").warn("hello world")
    Fiber.yield
    TestIO.to_s.should contain(" [WARN]-[test-1--main]: hello world")
    TestIO.clear
  end

  it "supports log level overrides" do
    DiagnosticLogger.new("override-level", level: :debug).debug("w3,sa")
    Fiber.yield
    TestIO.to_s.should contain("w3,sa")
    TestIO.clear

    DiagnosticLogger.new("override-level", level: :warn).info("hello")
    Fiber.yield
    TestIO.to_s.should eq("")
  end
end
