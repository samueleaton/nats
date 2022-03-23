module NATS
  class Subscription
    alias MessageChannel = Channel({Message, Proc(Exception, Nil)})

    getter subject : String
    getter sid : Int64
    getter queue_group : String?
    getter messages_remaining : Int32?
    private getter message_channel : MessageChannel

    def initialize(@subject, @sid, @queue_group, max_in_flight : Int = 10, &@block : Message, Subscription ->)
      @message_channel = MessageChannel.new(max_in_flight)
    end

    def unsubscribe_after(messages @messages_remaining : Int32)
    end

    def start
      spawn do
        remaining = @messages_remaining
        while remaining.nil? || remaining > 0
          message, on_error = message_channel.receive

          LOG.debug { "Calling subscription handler for sid #{sid} (subscription to #{subject.inspect}, message subject #{message.subject.inspect})" }
          call message, on_error

          remaining = @messages_remaining
        end
      rescue ex
      end
    end

    def close
      @message_channel.close
    end

    def send(message, &on_error : Exception ->) : Nil
      message_channel.send({message, on_error})
    end

    private def call(message, on_error : Exception ->) : Nil
      @block.call message, self
    rescue ex
      on_error.call ex
    ensure
      if remaining = @messages_remaining
        @messages_remaining = remaining - 1
      end
    end
  end
end
