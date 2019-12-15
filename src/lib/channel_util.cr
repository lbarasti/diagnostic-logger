class DiagnosticLogger
  module ChannelUtil
    def self.timer(span : Time::Span, name = "timer") : Channel(Nil)
      Channel(Nil).new(1).tap { |done|
        spawn(name: name) do
          sleep span
          done.send nil
          done.close
        end
      }
    end
    def self.batch(in_stream : Channel(T), max_size, max_time) : Channel(Enumerable(T)) forall T
      Channel(Enumerable(T)).new.tap { |out_stream|
        memory = Array(T).new(max_size)
        spawn do
          loop do
            timeout = timer(max_time)
            loop do
              select
              when v = in_stream.receive
                memory << v
                if memory.size >= max_size
                  out_stream.send(memory.dup)
                  memory.clear
                  break
                end
              when timeout.receive
                out_stream.send(memory.dup)
                memory.clear
                break
              end
            end
          rescue Channel::ClosedError
            out_stream.send(memory.dup)
            out_stream.close()
            break
          end
        end
      }
    end
  end
end