# JSON formatter/stringifier

class JSONFormatter
  def initialize(data, indent: 2)
    @data = data
    @indent = indent
  end

  def format
    format_value(@data, 0)
  end

  private

  def format_value(value, depth)
    case value
    when Hash
      format_object(value, depth)
    when Array
      format_array(value, depth)
    when String
      format_string(value)
    when Numeric
      value.to_s
    when true
      'true'
    when false
      'false'
    when nil
      'null'
    else
      format_string(value.to_s)
    end
  end

  def format_object(hash, depth)
    return '{}' if hash.empty?

    indent = ' ' * (@indent * (depth + 1))
    close_indent = ' ' * (@indent * depth)

    pairs = hash.map do |k, v|
      "#{indent}#{format_string(k.to_s)}: #{format_value(v, depth + 1)}"
    end

    "{\n#{pairs.join(",\n")}\n#{close_indent}}"
  end

  def format_array(arr, depth)
    return '[]' if arr.empty?

    indent = ' ' * (@indent * (depth + 1))
    close_indent = ' ' * (@indent * depth)

    items = arr.map do |v|
      "#{indent}#{format_value(v, depth + 1)}"
    end

    "[\n#{items.join(",\n")}\n#{close_indent}]"
  end

  def format_string(str)
    escaped = str.gsub('\\', '\\\\')
                 .gsub('"', '\\"')
                 .gsub("\n", '\\n')
                 .gsub("\t", '\\t')
                 .gsub("\r", '\\r')
    "\"#{escaped}\""
  end
end

def format_json(data, indent: 2)
  JSONFormatter.new(data, indent: indent).format
end
