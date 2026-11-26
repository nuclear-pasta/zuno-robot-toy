require_relative "./command_runner"

class CLI
    def initialize(argv)
        @argv = argv.dup
    end

    def run
        execute(argv.first)
        0
    end

    private

    attr_reader :argv

    def execute(path)
        if path
            File.open(path) { |file| runner_for(file).run }
        else
            runner_for($stdin).run
        end
    end

    def runner_for(input)
        CommandRunner.new(input, output: $stdout, warnings: $stderr)
    end
end
