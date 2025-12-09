#!/usr/bin/env ruby
# JSON tool - format, query, and manipulate JSON files
# A practical example of a portable CLI tool

def usage
  puts <<~USAGE
    json-tool - A portable JSON utility

    Usage:
      json-tool <command> [options] [file]

    Commands:
      format    Pretty-print JSON (reads from file or stdin)
      minify    Minify JSON (remove whitespace)
      keys      List all keys in a JSON object
      get       Get value at path (e.g., json-tool get users.0.name file.json)
      validate  Check if input is valid JSON

    Options:
      --indent N   Indentation spaces (default: 2)
      --help       Show this help

    Examples:
      json-tool format data.json
      echo '{"a":1}' | json-tool format
      json-tool get users.0.name data.json
      json-tool validate data.json
  USAGE
end

def read_input(file_arg)
  if file_arg && File.exist?(file_arg)
    File.open(file_arg, 'r') { |f| f.read }
  elsif !$stdin.tty?
    # Read from pipe/stdin - mruby may not support this well
    # For demo, just show message
    raise "Pipe input not fully supported - please specify a file"
  else
    raise "No input provided. Specify a file or pipe JSON input."
  end
end

def get_nested(data, path)
  parts = path.split('.')
  current = data

  parts.each do |part|
    if current.is_a?(Array)
      idx = part.to_i
      current = current[idx]
    elsif current.is_a?(Hash)
      # Try both string and symbol keys
      current = current[part] || current[part.to_sym]
    else
      return nil
    end
    return nil if current.nil?
  end

  current
end

def collect_keys(data, prefix = "")
  keys = []

  case data
  when Hash
    data.each do |k, v|
      full_key = prefix.empty? ? k.to_s : "#{prefix}.#{k}"
      keys << full_key
      keys.concat(collect_keys(v, full_key))
    end
  when Array
    data.each_with_index do |v, i|
      full_key = prefix.empty? ? i.to_s : "#{prefix}.#{i}"
      keys.concat(collect_keys(v, full_key))
    end
  end

  keys
end

# Parse arguments
command = ARGV[0]
args = ARGV[1..-1] || []
indent = 2
file_arg = nil

# Parse options
i = 0
while i < args.size
  case args[i]
  when '--indent'
    indent = args[i + 1].to_i
    i += 2
  when '--help', '-h'
    usage
  else
    file_arg = args[i]
    i += 1
  end
end

# Handle commands
case command
when 'format', 'fmt'
  input = read_input(file_arg)
  data = parse_json(input)
  puts format_json(data, indent: indent)

when 'minify', 'min'
  input = read_input(file_arg)
  data = parse_json(input)
  # Simple minification without regex
  formatted = format_json(data, indent: 0)
  minified = ""
  in_string = false
  formatted.each_char do |c|
    if c == '"' && (minified.empty? || minified[-1] != '\\')
      in_string = !in_string
    end
    if in_string || (c != "\n" && c != " ")
      minified << c
    end
  end
  puts minified

when 'keys'
  input = read_input(file_arg)
  data = parse_json(input)
  keys = collect_keys(data)
  keys.each { |k| puts k }

when 'get'
  path = args[0]
  file_arg = args[1]
  raise "Usage: json-tool get <path> <file>" unless path

  input = read_input(file_arg)
  data = parse_json(input)
  result = get_nested(data, path)

  if result.nil?
    puts "null"
  elsif result.is_a?(Hash) || result.is_a?(Array)
    puts format_json(result, indent: indent)
  else
    puts result
  end

when 'validate'
  input = read_input(file_arg)
  begin
    parse_json(input)
    puts "Valid JSON"
  rescue => e
    puts "Invalid JSON: #{e.message}"
  end

when 'help', '--help', '-h', nil
  usage

else
  $stderr.puts "Unknown command: #{command}"
  $stderr.puts "Run 'json-tool --help' for usage"
end
