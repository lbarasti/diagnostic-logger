class DiagnosticLogger
  module ChannelUtil
    private def self.timer(span : Time::Span, name = "timer") : Channel(Nil)
      Channel(Nil).new(1).tap { |done|
        spawn(name: name) do
          sleep span
          done.send nil
          done.close
        end
      }
    end

    # Sends batches of messages either every `size` messages received or every `interval`,
    # if a batch has not been sent within the last `interval`.
    def self.batch(in_stream : Channel(T), size : Int32, interval : Time::Span) : Channel(Enumerable(T)) forall T
      # TODO: assert on `size` and `interval`
      Channel(Enumerable(T)).new.tap { |out_stream|
        memory = Array(T).new(size)
        spawn do
          loop do
            timeout = timer(interval)
            sent = false
            loop do
              select
              when v = in_stream.receive
                memory << v
                if memory.size >= size
                  out_stream.send(memory.dup)
                  memory.clear
                  sent = true
                end
              when timeout.receive
                unless sent
                  out_stream.send(memory.dup)
                  memory.clear
                end
                break
              end
            end
          rescue Channel::ClosedError
            out_stream.send(memory.dup)
            out_stream.close
            break
          end
        end
      }
    end
  end
end
