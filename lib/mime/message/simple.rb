module MIME::Message
  class Simple
    # @return [Array] the MIME headers associated with this message
    attr_reader :headers

    # Retrieve the raw message body. For a Simple message this will be an Array of Strings that have US-ASCII
    # encoding; for a Multipart message, this will be an Array of MIME::Messages that together comprise the multipart
    # message.
    #
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