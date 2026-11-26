require "optparse"
require_relative "./command_runner"

# #run returns the exit status: 0 success, 1 unreadable input, 2 bad usage.
class CLI
    PROGRAM = "main.rb".freeze

    def initialize(argv)
        @argv = argv.dup
        @options = { verbose: false, help: false }
    end

    def run
        files = parser.parse(argv)
        return help if options[:help]
        return usage_error("too many arguments") if files.size > 1

        execute(files.first)
        0
    rescue OptionParser::ParseError => e
        usage_error(e.message)
    rescue SystemCallError => e
        $stderr.puts("Error: #{e.message}")
        1
    end

    private

    attr_reader :argv, :options

    def parser
        @parser ||= OptionParser.new do |opts|
            opts.banner = "Usage: ruby #{PROGRAM} [options] [FILE]"
            opts.separator("Reads commands from FILE, or from standard input when FILE is omitted.")
            opts.separator("")
            opts.on("-v", "--verbose", "Also log discarded commands to stderr") { options[:verbose] = true }
            opts.on("-h", "--help", "Show this help") { options[:help] = true }
        end
    end

    def execute(path)
        if path
            File.open(path) { |file| runner_for(file).run }
        else
            runner_for($stdin).run
        end
    end

    def runner_for(input)
        CommandRunner.new(input, output: $stdout, warnings: $stderr, log: ($stderr if options[:verbose]))
    end

    def help
        $stdout.puts(parser.help)
        0
    end

    def usage_error(message)
        $stderr.puts("Error: #{message}", parser.help)
        2
    end
end
