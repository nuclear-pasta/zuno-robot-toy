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

    describe "unclear lines raise" do
        it "UnknownCommand for an unknown word, extra arguments or a comment" do
            ["JUMP", "MOVE 1", "PLACEMENT 1,2,NORTH"].each do |line|
                expect { parse(line) }.to raise_error(CommandParser::UnknownCommand)
            end
        end

        it "WrongAmountOfArgs for a PLACE without exactly three arguments" do
            ["PLACE", "PLACE 1,2", "PLACE 1,2,NORTH,EXTRA", "PLACE 1,2,NORTH,", "PLACE ,1,2,NORTH", "PLACE MOVE"].each do |line|
                expect { parse(line) }.to raise_error(CommandParser::WrongAmountOfArgs)
            end
        end

        it "ArgumentNotAnInteger for a coordinate that is not plain digits" do
            ["PLACE a,2,NORTH", "PLACE 1,b,NORTH", "PLACE 1.5,2,NORTH", "PLACE +1,0,NORTH", "PLACE 1_0,0,NORTH", "PLACE ,1,NORTH"]
                .each { |line| expect { parse(line) }.to raise_error(CommandParser::ArgumentNotAnInteger) }
        end

        it "InvalidEncoding for a line that is not valid UTF-8, wherever the bad byte is" do
            expect { parse("\xFF\xFE".b) }
                .to raise_error(CommandParser::InvalidEncoding, 'not valid UTF-8: "\\xFF\\xFE"; re-save the file as UTF-8')
            expect { parse("MOVE caf\xE9".b) }.to raise_error(CommandParser::InvalidEncoding)
        end

        it "shares one base error class" do
            [CommandParser::WrongAmountOfArgs, CommandParser::ArgumentNotAnInteger,
             CommandParser::UnknownCommand, CommandParser::InvalidEncoding]
                .each { |error| expect(error).to be < CommandParser::Error }
        end
    end

    describe "error messages" do
        it "explain the problem and quote the line as the user wrote it" do
            expect { parse("PLACE 0,1 EAST") }
                .to raise_error(CommandParser::WrongAmountOfArgs, 'PLACE expects X,Y,DIRECTION but got "0,1 EAST"')
            expect { parse("place 1,b,north") }
                .to raise_error(CommandParser::ArgumentNotAnInteger, 'PLACE X and Y must be integers, got "b"')
            expect { parse("jump") }.to raise_error(CommandParser::UnknownCommand, 'unknown command "jump"')
        end
    end

    it "reads a String in any labelled encoding as UTF-8, without changing it" do
        line = +"PLACE 0,0,NORTH"
        expect(parse(line.b).args).to eq([0, 0, "NORTH"])
        expect(parse(line.encode("US-ASCII")).args).to eq([0, 0, "NORTH"])
        expect(line.encoding).to eq(Encoding::UTF_8)
    end
end
