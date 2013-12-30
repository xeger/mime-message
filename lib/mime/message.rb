module MIME
  # A MIME message, consisting of headers (stored as a Hash) and a body (array of lines in the
  # message).
  #
  module Message
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

    # Parse a MIME message from the given string. You can also pass an Array of strings, where each
    # string represents one line of the message.
    #
    # The option not to normalize is intended mainly for internal usage, when .parse is being called reentranly as
    # part of parsing a multipart message. In this case, the outermost call to .parse normalizes the line endings and
    # some lines have their CRLF stripped due to special treatment of empty lines that occur before boundary markers.
    # It is important NOT to renormalize the lines in order to preserve the exact content of each message part.
    #
    # @param [String, Array] text raw ASCII text of the message, or array of message lines
    # @param [Boolean] normalize if true, normalize all lines so they end in CRLF
    # @return [Message] a Ruby object representation of the message
    # @raise [ArgumentError] if the message is malformed
    def self.parse(text, normalize=true)
      if text.respond_to?(:split) # then it's a String!
        lines = split_lines(text)
      else
        lines = text
      end

      lines = normalize_lines(lines) if normalize

      headers, body = parse_headers_and_body(lines)

      content_type = headers['Content-Type']

      if !content_type.nil? && content_type.include?(MULTIPART)
        Multipart.new(headers, body)
      else
        Simple.new(headers, body)
      end
    end

    protected

    # Split a String into a collection of lines with no line endings.
    #
    # @param [String] text an entire MIME message, as a single ASCII string
    # @return [Array] the lines of the message, as an Array of String
    def self.split_lines(text)
      text.split(FUZZY_CRLF)
    end

    # Normalize the character encoding and line ending on a collection of lines, ensuring that they are 7-bit ASCII and
    # end with a CRLF.
    #
    # @param [Array] lines a collection of lines
    # @return [Array] a copy of the input with every line determined by CRLF
    def self.normalize_lines(lines)
      result = []

      if defined?(Encoding)
          # Ruby 1.9 and above - ensure that everything is encoded as US-ASCII
          lines.each_with_index do |l, i|
            begin
              o = l.encode(Encoding::US_ASCII)
              o.chomp!
              o << RFC822_CRLF
              result << o
            rescue Encoding::InvalidByteSequenceError
              raise Malformed.new("Invalid byte sequence for US-ASCII; input is not 7-bit clean", i+1)
            rescue Encoding::UndefinedConversionError
              raise Malformed.new("Undefined conversion for US-ASCII; input is not 7-bit clean", i+1)
            end
          end
      else
        # Ruby 1.8 - remain ignorant of character encodings
        lines.each_with_index do |l, i|
          o = l.chomp
          o << RFC822_CRLF
          result << o
        end
      end

      result
    end

    # Parse the headers and the body out of a message.
    #
    # @param [Array] lines the lines of a MIME message, as an Array of String
    # @return [Hash, Array] the message headers as a Hash of name to value, and the body as an Array of lines
    def self.parse_headers_and_body(lines)
      headers = {}
      body    = []

      # Simple state machine; see case statement below
      state   = :headers

      # Bind our local variables outside of the loop so they persist
      name    = nil
      value   = nil

      lines.each_with_index do |line, index|
        case state

        when :headers
          if match = RFC822_HEADER_NAME.match(line)
            # beginning of a new header
            unless name.nil?
              # save previous header if there was one
              h = Header.new(name, value)
              headers[h.name] = h
            end
            name  = match[1]
            value = line.split(':', 2)[1]
          elsif line[0, 1] =~ RFC822_LWSP # continuation of a folded header
            if name.empty? # we're not in the middle of a header!
              raise Malformed.new("Unexpected initial whitespace in headers section", index+1)
            else
              value.gsub!(/\r\n$/, '') # RFC822 says to ditch the CRLFs when "unfolding" a multi-line header
              value << line
            end
          elsif line == RFC822_CRLF
            # end of headers
            unless name.nil?
              # save previous header if there was one
              h = Header.new(name, value)
              headers[h.name] = h
            end
            state = :body
          else
            raise Malformed.new("Expected a header", index+1)
          end

        when :body
          body << line
        end
      end

      return headers, body
    end
  end
end

require 'mime/message/malformed'
require 'mime/message/header'
require 'mime/message/structured_field'
require 'mime/message/simple'
require 'mime/message/multipart'
