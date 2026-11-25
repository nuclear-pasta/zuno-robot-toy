require_relative "../lib/command_parser"

RSpec.describe CommandParser do
    def parse(input)
        described_class.new(input).parse_command
    end

    def command(name, *args)
        CommandParser::Command.new(name, args)
    end

    describe "valid lines" do
        it "parses MOVE, LEFT, RIGHT and REPORT" do
            %w[MOVE LEFT RIGHT REPORT].each { |name| expect(parse(name)).to eq(command(name)) }
        end

        it "parses PLACE into integers and a direction" do
            expect(parse("PLACE 1,2,NORTH")).to eq(command("PLACE", 1, 2, "NORTH"))
        end

        it "is case-insensitive and returns uppercase" do
            expect(parse("move")).to eq(command("MOVE"))
            expect(parse("place 1,2,NoRtH")).to eq(command("PLACE", 1, 2, "NORTH"))
        end

        it "ignores spaces, tabs and line endings around commands and arguments" do
            expect(parse("  MOVE\r\n")).to eq(command("MOVE"))
            expect(parse("\tPLACE 1 , 2 ,SOUTH \n")).to eq(command("PLACE", 1, 2, "SOUTH"))
        end

        it "returns nil for a blank line" do
            ["", "   ", "\n"].each { |line| expect(parse(line)).to be_nil }
        end

        it "reads leading zeros as decimal, and keeps a negative number for the table to refuse" do
            expect(parse("PLACE 010,07,NORTH").args).to eq([10, 7, "NORTH"])
            expect(parse("PLACE -1,0,NORTH").args).to eq([-1, 0, "NORTH"])
        end

        it "leaves the direction name for Robot to validate" do
            expect(parse("PLACE 1,2,UP").args).to eq([1, 2, "UP"])
            expect(parse("PLACE 1,2,").args).to eq([1, 2, ""])
        end
    end
end
