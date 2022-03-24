module NATS
  # Generic error
  class Error < ::Exception
  end

  # Raised when trying to reply to a NATS message that is not a reply.
  class NotAReply < Error
    getter nats_message : Message

    def initialize(error_message, @nats_message : Message)
      super error_message
    end
  end

  class ServerNotRespondingToPings < Error
  end

  class UnknownCommand < Error
  end
end
