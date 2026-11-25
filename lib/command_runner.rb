require "stringio"
require_relative "./command_parser"
require_relative "./table"
require_relative "./robot"
require_relative "./directions"

class CommandRunner
    # 5x5 tabletop: the highest coordinate is 4 on each axis.
    DEFAULT_TABLE = Table.new(4, 4)

    # input is a String or anything with #each_line; an IO is streamed line by line.
    def initialize(input, table: DEFAULT_TABLE, output: $stdout, warnings: nil, log: nil)
        @input = input
        @table = table
        @output = output
        @warnings = warnings
        @log = log
    end

    def run
        @robot = nil
        lines.each_line.with_index(1) do |line, number|
            command = parse(line, number)
            execute(command, number) if command
        end
        nil
    end

    private

    attr_reader :input, :table, :output, :warnings, :log, :robot

    def lines
        input.is_a?(String) ? StringIO.new(input) : input
    end

    def parse(line, number)
        CommandParser.new(line).parse_command
    rescue CommandParser::Error => e
        warn_about(number, e.message)
        nil
    end

    def execute(command, number)
        return place(*command.args) if command.command == "PLACE"
        return ignore(number, "robot is not placed") unless robot

        case command.command
        when "MOVE" then ignore(number, "would fall off the table") unless robot.move
        when "REPORT" then report
        when *Directions::ROTATIONS then robot.rotate(command.command)
        end
    # An unknown direction or rotation is an invalid line: warn. An off-table
    # position is a valid PLACE that cannot be carried out: only log.
    rescue Robot::InvalidDirection, Robot::InvalidRotation => e
        warn_about(number, e.message)
    rescue Robot::InvalidPlacement => e
        ignore(number, e.message)
    end

    def place(x, y, facing)
        @robot = Robot.new(x, y, facing, table)
    end

    def report
        output.puts(robot.report)
    end

    def warn_about(number, reason)
        warnings&.puts("warning: line #{number}: ignored (#{reason})")
    end

    def ignore(number, reason)
        log&.puts("line #{number}: ignored (#{reason})")
    end
end
