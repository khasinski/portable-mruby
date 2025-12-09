# Simple JSON parser (mruby doesn't have JSON stdlib by default)
# This is a basic implementation for demonstration

class JSONParser
  def initialize(json_string)
    @json = json_string.strip
    @pos = 0
  end

  def parse
    skip_whitespace
    parse_value
  end

  private

  def parse_value
    skip_whitespace
    case current_char
    when '{'
      parse_object
    when '['
      parse_array
    when '"'
      parse_string
    when 't'
      parse_true
    when 'f'
      parse_false
    when 'n'
      parse_null
    when '-', '0'..'9'
      parse_number
    else
      raise "Unexpected character: #{current_char.inspect} at position #{@pos}"
    end
  end

  def parse_object
    result = {}
    advance # skip '{'
    skip_whitespace

    return result if current_char == '}'

    loop do
      skip_whitespace
      key = parse_string
      skip_whitespace
      expect(':')
      skip_whitespace
      value = parse_value
      result[key] = value
      skip_whitespace

      case current_char
      when '}'
        advance
        return result
      when ','
        advance
      else
        raise "Expected ',' or '}' in object"
      end
    end
  end

  def parse_array
    result = []
    advance # skip '['
    skip_whitespace

    return result if current_char == ']'

    loop do
      skip_whitespace
      result << parse_value
      skip_whitespace

      case current_char
      when ']'
        advance
        return result
      when ','
        advance
      else
        raise "Expected ',' or ']' in array"
      end
    end
  end

  def parse_string
    expect('"')
    result = ""

    while current_char != '"'
      if current_char == '\\'
        advance
        case current_char
        when '"', '\\', '/'
          result << current_char
        when 'n'
          result << "\n"
        when 't'
          result << "\t"
        when 'r'
          result << "\r"
        else
          result << current_char
        end
      else
        result << current_char
      end
      advance
    end

    advance # skip closing '"'
    result
  end

  def parse_number
    start_pos = @pos
    advance if current_char == '-'

    while digit?(current_char)
      advance
    end

    if current_char == '.'
      advance
      while digit?(current_char)
        advance
      end
    end

    if current_char == 'e' || current_char == 'E'
      advance
      advance if current_char == '+' || current_char == '-'
      while digit?(current_char)
        advance
      end
    end

    num_str = @json[start_pos...@pos]
    num_str.include?('.') || num_str.include?('e') || num_str.include?('E') ?
      num_str.to_f : num_str.to_i
  end

  def digit?(char)
    char && char >= '0' && char <= '9'
  end

  def parse_true
    expect_literal('true')
    true
  end

  def parse_false
    expect_literal('false')
    false
  end

  def parse_null
    expect_literal('null')
    nil
  end

  def current_char
    @json[@pos]
  end

  def advance
    @pos += 1
  end

  def skip_whitespace
    while whitespace?(current_char)
      advance
    end
  end

  def whitespace?(char)
    char == ' ' || char == "\t" || char == "\n" || char == "\r"
  end

  def expect(char)
    raise "Expected '#{char}', got '#{current_char}'" unless current_char == char
    advance
  end

  def expect_literal(str)
    str.each_char do |c|
      raise "Expected '#{c}', got '#{current_char}'" unless current_char == c
      advance
    end
  end
end

def parse_json(str)
  JSONParser.new(str).parse
end
