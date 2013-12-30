module MIME::Message
  # A MIME header. Headers have a name, a raw value, and occasionally they have
  # one or more parameters as semicolon-separated name=value pairs.
  #
  # This class exists primarily to take care of parsing header parameters.
  #
  # @todo understand which other structured headers there are
  class Header
    # The sequence of characters that separates a header's simple value from its
    # parameters (or one parameter from another).
    PARAMETER_SEPARATOR = /;\s*/

    # The canonicalized name of this header
    # @return [String]
    attr_reader :name

    # The canonicalized raw value of this header, including parameters
    # @return [String]
    attr_reader :value

    # The canonicalized raw value of this header, excluding any parameters.
    # For a header with no parameters, this is equivalent to #value.
    # @return [String]
    attr_reader :value_without_parameters

    # The parameters of this header, if any
    # @return [String]
    attr_reader :parameters

    def initialize(name, value)
      @name, @value = canonical_name(name, true), StructuredField.new(value.strip)
      @parameters = {}

      if @value.include?(';')
        parameters = @value.split(PARAMETER_SEPARATOR).compact

        # The simple value is anything before the first semicolon
        @value_without_parameters = parameters.shift

        # Everything after the first semicolon is taken to be a parameter
        parameters.each do |param|
          name, value = param.split('=', 2)
          @parameters[canonical_name(name, false)] = StructuredField.new(value)
        end
      else
        @value_without_parameters = @value
      end
    end

    # @return [String] the string representation of this header's name and value
    def to_s
      "%s: %s\r\n" % [name, value.strip]
    end

    # As a convenience, any missing method will be dispatched to the value object, allowing
    # this object to be treated like a header value.
    def respond_to?(meth)
      super(meth) || @value.respond_to?(meth)
    end

    # As a convenience, any missing method will be dispatched to the value object, allowing
    # this object to be treated like a header value.
    def method_missing(meth, *args)
      @value.__send__(meth, *args)
    end

    private

    # Canonicalize a header name. This is useful because RFC822 specifies case-insensitive
    # header names, which is a pain to code for. Better to canonicalize everything up front.
    #
    # We use the same canonicalization scheme as HTTP: the name is split into runs of alphanumeric
    # characters separated by anything else and the first character of each run is capitalized;
    # all other characters a lower-cased.
    #
    # @param [String] name an ASCII header name
    # @param [Boolean] transform_case if true, perform HTTP-style capitalization (title-case split by hyphens)
    # @return [String] the canonicalized header name
    def canonical_name(name, transform_case)
      canonical = ''
      state     = :begin

      name.strip.each_char do |char|
        case state
        when :begin
          canonical << (transform_case ? char.upcase : char)
          state = :continue
        else
          if char =~ /[A-Za-z0-9]/
            canonical << (transform_case ? char.downcase : char)
          else
            canonical << char
            state = :begin
          end
        end
      end

      canonical
    end
  end
end