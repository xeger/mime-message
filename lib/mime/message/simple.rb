require 'mime-types'

module MIME::Message
  class Simple
    # This message's headers. Header names are always stored and accessed using canonicalized names a la HTTP; for
    # instance, a message with header 'CoNTent-TYPE' will be re
    #
    # @return [Hash] a hash of MIME headers associated with this message
    attr_reader :headers

    # Retrieve the raw message body. For a Simple message this will be an Array of Strings with US-ASCII encoding; for
    # a Multipart message, this will be an Array of MIME::Message objects.
    #
    # @return [Array] an array of message lines (or body parts, for a multipart message)
    attr_reader :body

    # @return [String] the string representation of this entire message, including headers and CRLFs
    def to_s
      result = ''

      @headers.each_pair do |_, v|
        result << v.to_s
      end
      result << "\r\n"

      body.each do |l|
        result << l
      end

      result
    end

    # Determine the MIME type of this message's content.
    #
    # @return [MIME::Type] the declared content type, or text/plain if no Content-Type header is present
    def content_type
      if headers.key?('Content-Type')
        typename = headers['Content-Type'].value_without_parameters
      else
        typename = 'text/plain'
      end

      MIME::Types[typename].first
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