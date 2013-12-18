module MIME
  # A MIME message, consisting of headers (stored as a Hash) and a body (array of lines in the
  # message).
  #
  class Message
    # Matches any potential CR/LF-like sequence. This is more tolerant than RFC822, but useful in
    # cases where someone has run a message through a non-CRLF operating system.
    FUZZY_CRLF         = /\r\n|\n\r|\r|\n/

    # CRLF        = CR LF
    RFC822_CRLF        = "\r\n"

    # LWSP-char   =  SPACE / HTAB
    RFC822_LWSP        = /[ \t]/

    # Matches the field-name portion of an RFC822 header field.
    #
    # field       =  field-name ":" [ field-body ] CRLF
    # field-name  =  1*<any CHAR, excluding CTLs, SPACE, and ":">
    RFC822_HEADER_NAME = /^([^\x00-\x0f\x7f :]+):/

    # MIME type prefix that signifies a multipart message.
    MULTIPART          = 'multipart/'

    # @return [Array] the MIME headers associated with this message
    attr_reader :headers

    # @return [Array] an array of message lines (or body parts, for a multipart message)
    attr_reader :body

    # Parse a MIME message from the given string.
    #
    # @param [String, Array] text raw ASCII text of the message, or array of message lines
    # @return [Message] a Ruby object representation of the message
    # @raise [ArgumentError] if the message is malformed
    def self.parse(text)
      if text.respond_to?(:split)
        lines = split_lines(text)
      else
        lines = text
      end

      headers, body = parse_headers_and_body(lines)

      content_type = headers.detect { |h| h.name == 'Content-Type' }

      if content_type.nil? || !content_type.include?(MULTIPART)
        self.new(headers, body)
      else
        Multipart.new(headers, body)
      end
    end

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

    # Given a MIME message contained in a single String, split it into an Array of lines and strip the CRLF.
    #
    # @param [String] text an entire MIME message, as a single ASCII string
    # @return [Array] the lines of the message, as an Array of String
    def self.split_lines(text)
      text.split(FUZZY_CRLF).map { |l| "#{l}\r\n" }
    end

    # Parse the headers and the body out of a message.
    #
    # @param [Array] lines the lines of a MIME message, as an Array of String
    # @return [Hash, Array] the message headers as a Hash of name to value, and the body as an Array of lines
    def self.parse_headers_and_body(lines)
      headers = []
      body    = []

      # Simple state machine; see case statement below
      state   = :headers

      # Bind our local variables outside of the loop so they persist
      name    = nil
      value   = nil

      lines.each do |line|
        case state

        when :headers
          if match = RFC822_HEADER_NAME.match(line)
            # beginning of a new header
            unless name.nil?
              headers << Header.new(name, value) # save last header if there was one
            end
            name  = match[1]
            value = line.split(':', 2)[1]
          elsif line[0, 1] =~ RFC822_LWSP # continuation of a folded header
            if name.empty? # we're not in the middle of a header!
              raise ArgumentError, "Invalid MIME message: unexpected initial whitespace in headers section"
            else
              value.gsub!(/\r\n$/, '') # RFC822 says to ditch the CRLFs when "unfolding" a multi-line header
              value << line
            end
          elsif line == RFC822_CRLF
            # end of headers
            unless name.nil?
              # save last header if there was one
              headers << Header.new(name, value)
            end
            state = :body
          else
            raise ArgumentError, "Invalid MIME message: expecting a header"
          end

        when :body
          body << line
        end
      end

      return headers, body
    end
  end
end

require 'mime/message/header'
require 'mime/message/structured_field'
require 'mime/message/multipart'
