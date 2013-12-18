class MIME::Message
  class StructuredField < String
    def parsed_value
      state  = :cdata
      output = ''

      self.each_char do |c|
        case state
        when :cdata
          if c =~ MIME::Message::RFC822_LWSP
            state = :space
          elsif c == '"'
            state = :quoted
          else
            output << c
          end

        when :space
          if c =~ MIME::Message::RFC822_LWSP
            # no-op; eating whitespace
          else
            output << ' ' # canonicalize whitespace to a single 0x32 char
            output << c
            state = :cdata
          end

        when :quoted
          case c
          when '\\'
            state = :escaped
          when '"'
            state = :terminal
          else
            output << c
          end

        when :escaped
          output << c
          state = :quoted

        when :terminal
          #no-op; ignore all further input
        end
      end

      return output.strip #remove leading/trailing whitespace for good measure
    end
  end
end
