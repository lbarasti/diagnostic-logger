require "../../src/diagnostic_logger"

log = DiagnosticLogger.new("to-file")
log.info("hello world")
