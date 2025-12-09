# portable_mruby

Build truly portable Ruby executables that run on Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD from a single binary.

## Quick Start

```bash
# Install
gem install portable_mruby

# Create a Ruby program
echo 'puts "Hello from #{RUBY_ENGINE}!"' > hello.rb

# Build portable executable
portable-mruby build -e hello.rb -o hello.com

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
# Build a single-file Ruby program
portable-mruby build --entry main.rb --output myapp.com

# Run on any supported platform
./myapp.com
```

### Multi-file Projects

```bash
# Build a project with multiple Ruby files
portable-mruby build --entry main.rb --dir src/ --output myapp.com
```

All `.rb` files in the directory are compiled and included. The entry file is executed last.

### Options

```
Usage: portable-mruby build [options]

Options:
    -e, --entry FILE        Entry point Ruby file (required)
    -d, --dir DIR           Source directory (default: .)
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
portable-mruby build -e main.rb --mruby-source ~/mruby -o myapp.com
```

## Example

Create a simple Ruby program:

```ruby
# main.rb
name = ARGV[0] || 'World'
puts "Hello, #{name}!"
puts "Running on: #{RUBY_ENGINE} #{RUBY_VERSION}"
puts "Time: #{Time.now}"
```

Build it:

```bash
portable-mruby build --entry main.rb --output hello.com
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
# lib/greeter.rb
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
# main.rb
greeter = Greeter.new(ARGV[0] || 'World')
puts greeter.greet
```

```bash
portable-mruby build -e main.rb -d myapp/ -o greeter.com
./greeter.com Ruby  # => Hello, Ruby!
```

## mruby vs CRuby

mruby is a lightweight Ruby implementation. Key differences:

| Feature | CRuby | mruby |
|---------|-------|-------|
| `require`/`require_relative` | Yes | No (all files compiled together) |
| Gems | Yes | No |
| Native extensions | Yes | No |
| Regexp | Yes | Optional (not included by default) |
| Standard library | Full | Core subset |

**Available in mruby**: Classes, modules, blocks, procs, lambdas, exceptions, File I/O, Dir, Time, Math, Struct, Fiber, sockets, and more.

**Not available**: `require`, gems, Regexp (by default), `sleep`, some stdlib classes.

## Binary Size

| Type | Size |
|------|------|
| Simple programs | ~2.7 MB |
| Complex programs | ~2.7-3 MB |

The base mruby runtime accounts for most of the size. Additional Ruby code adds minimal overhead since it compiles to compact bytecode.

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

Ensure you have enough disk space (~300MB for cosmocc). You can also manually install cosmocc:

```bash
mkdir -p ~/.portable-mruby/cosmocc
cd ~/.portable-mruby/cosmocc
wget https://cosmo.zip/pub/cosmocc/cosmocc.zip
unzip cosmocc.zip
```

### Using a pre-installed cosmocc

```bash
export COSMO_ROOT=/path/to/cosmocc
portable-mruby build -e main.rb -o app.com
```

## License

MIT License
