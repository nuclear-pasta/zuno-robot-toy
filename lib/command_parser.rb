require_relative "./directions"

class CommandParser
    SIMPLE = (%w[MOVE REPORT] + Directions::ROTATIONS).freeze
    PLACE = "PLACE"
    Command = Struct.new(:command, :args)

    # Always read as UTF-8, whatever the system locale says.
    def initialize(line)
        @line = line.dup.force_encoding(Encoding::UTF_8)
    end

    def parse_command
        if command.empty?
            nil
        elsif SIMPLE.include?(command.upcase)
            Command.new(command.upcase, [])
        elsif command.split(" ").first.upcase == PLACE
            parse_place
        end
    end

    private

    attr_reader :line

    def command
        @command ||= line.strip
    end

    def parse_place
        name, raw_args = command.split(" ", 2)
        # -1 keeps trailing empty fields, so "1,2,NORTH," is rejected, not trimmed.
        args = raw_args.to_s.split(",", -1).map(&:strip)
        Command.new(name.upcase, [args[0].to_i, args[1].to_i, args[2].upcase])
    end
end
