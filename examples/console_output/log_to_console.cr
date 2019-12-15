require "../../src/diagnostic_logger"
require "uuid"

log = DiagnosticLogger.new("to-console")

1000.times { |i|
  spawn(name: "f_#{i}") do
    sleep 2 * rand
    log.info(UUID.random.to_s)
  end
}

sleep 5