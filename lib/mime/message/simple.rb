module MIME::Message
  class Simple
    # @return [Array] the MIME headers associated with this message
    attr_reader :headers

    # @return [Array] an array of message lines (or body parts, for a multipart message)
    attr_reader :body

    # Print the string representation of this message.
    def to_s
      headers.map(&:to_s).join('') + "\r\n" + body.map(&:to_s).join('')
    end

    private

    # Create a new Message.
    #
    # @param [Array] headers a collection of Header objects
    # @param [Array] body the lines of the message body
    def initialize(headers, body)
      @headers = headers
      @body    = body
    end
  end
end