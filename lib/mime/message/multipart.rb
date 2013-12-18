class MIME::Message
  # A MIME multipart message. The body of a multipart message is an array of
  # Messages, each of which has its own headers and body.
  class Multipart < MIME::Message
    # Any lines of ASCII text that appear before the first boundary are the preamble.
    # They're not technically part of the multipart message; they're merely there to
    # give non-MIME readers a clue as to what's happening.
    attr_reader :boundary, :preamble, :postamble

    # Create a new Multipart.
    #
    # @param [Array] headers a collection of Header objects
    # @param [Array] body the lines of the multipart message body
    def initialize(headers, body)
      content_type = headers.detect { |h| h.name == 'Content-Type' }
      boundary     = content_type.parameters['boundary']

      if boundary.nil?
        raise ArgumentError, "Malformed multipart message: expected Content-Type to contain 'boundary' parameter"
      else
        @boundary      = boundary.parsed_value
        boundary_tween = Regexp.new("--#{Regexp.escape(@boundary)}\s*[\r\n]*$")
        boundary_last  = Regexp.new("--#{Regexp.escape(@boundary)}--\s*[\r\n]*$")
      end

      parts      = []
      @preamble  = []
      part_lines = []
      @postamble = []
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
            parts << MIME::Message.parse(part_lines)
            part_lines = []
          elsif line =~ boundary_last
            part_lines.last.gsub!(/[\r\n]+$/, '') # swallow CRLF before boundary marker
            part_lines.pop if part_lines.last.empty? # get rid of extra newline if it was present
            parts << MIME::Message.parse(part_lines)
            part_lines = []
            state = :postamble
          else
            part_lines << line
          end

        when :postamble
          @postamble << line
        end
      end

      super(headers, parts)
    end

    def to_s
      @headers.map(&:to_s).join('') + "\r\n" + preamble.join('') + "--#{boundary}\r\n" + body.map(&:to_s).join("\r\n--#{boundary}\r\n") + "\r\n--#{boundary}--\r\n" + postamble.join('')
    end
  end
end