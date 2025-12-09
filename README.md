# portable_mruby

Build truly portable Ruby executables that run on Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD from a single binary.

## Quick Start

```bash
# Install
gem install portable_mruby

# Create a Ruby program
mkdir myapp
echo 'puts "Hello from #{RUBY_ENGINE}!"' > myapp/hello.rb

# Build portable executable
portable-mruby build -d myapp -o hello.com

# Run it (works on Linux, macOS, Windows, FreeBSD, OpenBSD, NetBSD)
./hello.com
```

## How it Works

portable_mruby uses [mruby](https://mruby.org/) (embedded Ruby) compiled with [Cosmopolitan Libc](https://github.com/jart/cosmopolitan) to create "Actually Portable Executables" (APE). These are single binaries that run natively on multiple operating systems and CPU architectures without any dependencies.

## Supported Platforms

A single binary runs on:
- Linux (x86_64, ARM64)
- macOS (x86_64, ARM64)
- Windows (x86_64)
- FreeBSD (x86_64)
- OpenBSD (x86_64)
- NetBSD (x86_64)

## Installation

```bash
gem install portable_mruby
```

On first build, the Cosmopolitan toolchain (~60MB) will be automatically downloaded to `~/.portable-mruby/cosmocc/`.

## Usage

### Basic Usage

```bash
# Build all .rb files in a directory
portable-mruby build -d src/ -o myapp.com

# Run on any supported platform
./myapp.com
```

All `.rb` files in the directory (recursively) are compiled and executed in sorted order.

### With Entry Point

When you have multiple files and need a specific file to run last (e.g., your main program that uses classes defined in other files):

```bash
# Specify an entry file (runs last, after all other files)
portable-mruby build -d src/ -e main.rb -o myapp.com
```

**Important:** The `-e` (entry) path is relative to the `-d` (directory) path. In the example above, it looks for `src/main.rb`.

### Options

```
Usage: portable-mruby build [options]

Options:
    -d, --dir DIR           Source directory containing .rb files (required)
    -e, --entry FILE        Entry point Ruby file, relative to -d (runs last)
    -o, --output FILE       Output binary name (default: app.com)
    --mruby-source DIR      Build mruby from custom source directory
    -v, --verbose           Verbose output
    -h, --help              Show help

Environment Variables:
    COSMO_ROOT              Path to cosmocc toolchain (auto-downloaded if not set)
```

### Using Custom mruby

If you need custom mruby gems or configuration, you can build from source:

```bash
# Clone mruby with your customizations
git clone https://github.com/mruby/mruby.git ~/mruby

# Build using your custom mruby
portable-mruby build -d src/ --mruby-source ~/mruby -o myapp.com
```

## Example

Create a simple Ruby program:

```bash
mkdir hello
cat > hello/main.rb << 'EOF'
name = ARGV[0] || 'World'
puts "Hello, #{name}!"
puts "Running on: #{RUBY_ENGINE} #{RUBY_VERSION}"
puts "Time: #{Time.now}"
EOF
```

Build it:

```bash
portable-mruby build -d hello -o hello.com
```

Run it anywhere:

```bash
$ ./hello.com Alice
Hello, Alice!
Running on: mruby 3.4
Time: 2025-12-09 12:00:00 +0000
```

## Multi-file Example

```
myapp/
  lib/
    greeter.rb
  main.rb
```

```ruby
# myapp/lib/greeter.rb
class Greeter
  def initialize(name)
    @name = name
  end

  def greet
    "Hello, #{@name}!"
  end
end
```

```ruby
# myapp/main.rb
greeter = Greeter.new(ARGV[0] || 'World')
puts greeter.greet
```

```bash
# Build with main.rb as entry point (runs last, after lib/greeter.rb)
portable-mruby build -d myapp -e main.rb -o greeter.com
./greeter.com Ruby  # => Hello, Ruby!
```

Files are loaded in sorted order (`lib/greeter.rb` before `main.rb`), but `-e main.rb` ensures it runs last regardless of sort order.

## Build Process

1. Ruby source files are compiled to mruby bytecode using `mrbc`
2. Bytecode is embedded in a C source file as byte arrays
3. A minimal C runtime initializes mruby and loads the bytecode
4. Everything is compiled with Cosmopolitan's `cosmocc` compiler
5. The result is an APE binary - a polyglot that runs on all platforms

## Troubleshooting

### "Bundled mrbc not found"

The gem installation may be corrupted. Reinstall:

```bash
gem uninstall portable_mruby
gem install portable_mruby
```

### Build fails with cosmocc errors

Ensure you have enough disk space (~60MB for cosmocc download, ~200MB extracted). You can also manually install cosmocc:

```bash
mkdir -p ~/.portable-mruby/cosmocc
cd ~/.portable-mruby/cosmocc
wget https://cosmo.zip/pub/cosmocc/cosmocc.zip
unzip cosmocc.zip
```

### Using a pre-installed cosmocc

```bash
export COSMO_ROOT=/path/to/cosmocc
portable-mruby build -d src/ -o app.com
```

## License

MIT License
