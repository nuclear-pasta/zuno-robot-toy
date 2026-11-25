require_relative "./directions"

class CommandParser
    class Error < StandardError; end
    class WrongAmountOfArgs < Error; end
    class ArgumentNotAnInteger < Error; end
    class UnknownCommand < Error; end

    SIMPLE = (%w[MOVE REPORT] + Directions::ROTATIONS).freeze
    PLACE = "PLACE"
    INTEGER = /\A-?\d+\z/ # simple digits-only check; see "better validation" in the README
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
        else
            raise UnknownCommand, "unknown command #{command.inspect}"
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
        validate_args(args)
        Command.new(name.upcase, [args[0].to_i, args[1].to_i, args[2].upcase])
    end

    def validate_args(args)
        unless args.size == 3
            raise WrongAmountOfArgs, "PLACE expects X,Y,DIRECTION but got #{args.join(",").inspect}"
        end

        args.first(2).each do |value|
            next if INTEGER.match?(value)

            raise ArgumentNotAnInteger, "PLACE X and Y must be integers, got #{value.inspect}"
        end
    end
end
