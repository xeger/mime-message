class MIME::Message
  class Malformed < Exception
    attr_reader :line

    def initialize(message, line)
      super("Line #{line}: " + message)
      @line = line
    end
  end
end