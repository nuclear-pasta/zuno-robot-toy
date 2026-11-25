require "stringio"
require_relative "./command_parser"
require_relative "./table"
require_relative "./robot"
require_relative "./directions"

class CommandRunner
    # 5x5 tabletop: the highest coordinate is 4 on each axis.
    DEFAULT_TABLE = Table.new(4, 4)

    # input is a String or anything with #each_line; an IO is streamed line by line.
    def initialize(input, table: DEFAULT_TABLE, output: $stdout)
        @input = input
        @table = table
        @output = output
    end

    def run
        @robot = nil
        lines.each_line do |line|
            command = parse(line)
            execute(command) if command
        end
        nil
    end

    private

    attr_reader :input, :table, :output, :robot

    def lines
        input.is_a?(String) ? StringIO.new(input) : input
    end

    def parse(line)
        CommandParser.new(line).parse_command
    end

    def execute(command)
        return place(*command.args) if command.command == "PLACE"

        case command.command
        when "MOVE" then robot.move
        when "REPORT" then report
        when *Directions::ROTATIONS then robot.rotate(command.command)
        end
    end

    def place(x, y, facing)
        @robot = Robot.new(x, y, facing, table)
    end

    def report
        output.puts(robot.report)
    end
end
