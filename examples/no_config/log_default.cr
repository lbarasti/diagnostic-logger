require "../../src/diagnostic_logger"
require "uuid"

raise Exception.new("No config file should be provided") if File.exists?("config.yml")

log = DiagnosticLogger.new("default_logger")

1000.times { |i|
  spawn(name: "f_#{i}") do
    sleep 2 * rand
    log.info(UUID.random.to_s)
  end
}

sleep 3
