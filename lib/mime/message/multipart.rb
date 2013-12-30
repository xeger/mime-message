module MIME::Message
  # A MIME multipart message. The body of a multipart message is an array of
  # Messages, each of which has its own headers and body.
  class Multipart < Simple
    # Any lines of ASCII text that appear before the first boundary are the preamble.
    # They're not technically part of the multipart message; they're merely there to
    # give non-MIME readers a clue as to what's happening.
    attr_reader :boundary, :preamble, :epilogue

    # Create a new Multipart.
    #
    # @param [Array] headers a collection of Header objects
    # @param [Array] body the lines of the multipart message body
    def initialize(headers, body)
      content_type = headers['Content-Type']
      boundary     = content_type.parameters['boundary']

      if boundary.nil?
        raise MalformedMessage.new("Malformed multipart message: expected Content-Type header to contain 'boundary' parameter",
                                   1)
      else
        @boundary      = boundary.parsed_value
        boundary_tween = Regexp.new("--#{Regexp.escape(@boundary)}\s*\r\n$")
        boundary_last  = Regexp.new("--#{Regexp.escape(@boundary)}--\s*\r\n$")
      end

      parts      = []
      @preamble  = []
      part_lines = []
      @epilogue = []
      state      = :preamble

      body.each do |line|
        case state
        when :preamble
          if line =~ boundary_tween
            state = :part
          else
            @preamble << line
          end

        when :part
          if line =~ boundary_tween
            part_lines.last.gsub!(/[\r\n]+$/, '') # swallow CRLF before boundary marker
            part_lines.pop if part_lines.last.empty? # get rid of extra newline if it was present
            parts << MIME::Message.parse(part_lines, false)
            part_lines = []
          elsif line =~ boundary_last
            part_lines.last.gsub!(/[\r\n]+$/, '') # swallow CRLF before boundary marker
            part_lines.pop if part_lines.last.empty? # get rid of extra newline if it was present
            parts << MIME::Message.parse(part_lines, false)
            part_lines = []
            state = :epilogue
          else
            part_lines << line
          end

        when :epilogue
          @epilogue << line
        end
      end

      # Handle messages that have no epilogue
      unless part_lines.empty?
        parts << MIME::Message.parse(part_lines, false)
      end

      super(headers, parts)
    end

    # @return [String] the string representation of this entire message, including headers, CRLFs, preamble, postamble and all boundaries
    def to_s
      result = ''

      @headers.each_pair do |_, v|
        result << v.to_s
      end
      result << "\r\n"

      preamble.each do |l|
        result << l
      end

      result << "--#{boundary}\r\n"
      body.each do |l|
        result << l
        result << "\r\n--#{boundary}\r\n"
      end
      result << "\r\n--#{boundary}--\r\n"

      epilogue.each do |l|
        result << l
      end

      result
    end
  end
end