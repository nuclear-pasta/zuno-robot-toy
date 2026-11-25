require "stringio"
require_relative "../lib/command_runner"

RSpec.describe CommandRunner do
    # Runs the input and returns the REPORT lines that were written.
    def run(input, **options)
        output = StringIO.new
        described_class.new(input, output: output, **options).run
        output.string.lines.map(&:chomp)
    end

    # Runs the input and returns the lines written to the given stream.
    def lines_written_to(stream, input)
        io = StringIO.new
        described_class.new(input, output: StringIO.new, stream => io).run
        io.string.lines.map(&:chomp)
    end

    def log_for(input)
        lines_written_to(:log, input)
    end

    def warnings_for(input)
        lines_written_to(:warnings, input)
    end

    describe "example scenarios" do
        it "A: basic movement" do
            expect(run("PLACE 0,0,NORTH\nMOVE\nREPORT")).to eq(["0,1,NORTH"])
        end

        it "B: rotation" do
            expect(run("PLACE 0,0,NORTH\nLEFT\nREPORT")).to eq(["0,0,WEST"])
        end

        it "C: complex sequence" do
            expect(run("PLACE 1,2,EAST\nMOVE\nMOVE\nLEFT\nMOVE\nREPORT")).to eq(["3,3,NORTH"])
        end
    end

    describe "valid commands that cannot be carried out" do
        it "discards everything before the first valid PLACE, an off-table PLACE included" do
            text = "MOVE\nREPORT\nPLACE 5,5,NORTH\nMOVE\nREPORT\nPLACE 1,1,SOUTH\nREPORT"
            expect(run(text)).to eq(["1,1,SOUTH"])
        end

        it "ignores an off-table PLACE once placed, and allows placing again" do
            text = "PLACE 1,1,NORTH\nPLACE 9,9,SOUTH\nREPORT\nPLACE 3,3,WEST\nREPORT"
            expect(run(text)).to eq(["1,1,NORTH", "3,3,WEST"])
        end

        it "ignores a MOVE that would fall off and keeps accepting commands" do
            expect(run("PLACE 0,0,SOUTH\nMOVE\nREPORT\nLEFT\nMOVE\nREPORT")).to eq(["0,0,SOUTH", "1,0,EAST"])
        end

        it "uses a 5x5 table by default, or the table it is given" do
            expect(run("PLACE 4,4,NORTH\nMOVE\nREPORT")).to eq(["4,4,NORTH"])
            expect(run("PLACE 5,0,EAST\nREPORT")).to eq([])
            expect(run("PLACE 2,0,EAST\nREPORT", table: Table.new(1, 1))).to eq([])
        end
    end

    describe "invalid lines are skipped with a warning" do
        it "keeps going and never moves the robot because of them" do
            text = "PLACE 2,2,NORTH\nPLACE 1,2,UP\nJUMP\nMOVE 1\nPLACE a,2,NORTH\nPLACE 1,2\nMOVE\nREPORT"
            expect(run(text)).to eq(["2,3,NORTH"])
        end

        it "warns with the line number and the reason, counting blank lines" do
            text = "\nJUMP\nPLACE 1,2,UP\nPLACE 1,2\nPLACE a,2,NORTH"
            expect(warnings_for(text)).to eq([
                %(warning: line 2: ignored (unknown command "JUMP")),
                %(warning: line 3: ignored ("UP" is not one of NORTH, EAST, SOUTH, WEST)),
                %(warning: line 4: ignored (PLACE expects X,Y,DIRECTION but got "1,2")),
                %(warning: line 5: ignored (PLACE X and Y must be integers, got "a"))
            ])
        end

        it "does not warn about valid commands that were discarded, or blank lines" do
            expect(warnings_for("MOVE\n\nPLACE 9,9,NORTH\nPLACE 0,0,SOUTH\nMOVE\nREPORT")).to eq([])
        end
    end

    describe "log" do
        it "explains each kind of discarded command, with its line number" do
            text = "MOVE\nPLACE 9,9,NORTH\nPLACE 0,0,SOUTH\nMOVE"
            expect(log_for(text)).to eq([
                "line 1: ignored (robot is not placed)",
                "line 2: ignored (position 9,9 is not on the table: x must be between 0 and 4, y must be between 0 and 4)",
                "line 4: ignored (would fall off the table)"
            ])
        end

        it "stays empty for valid commands and for invalid lines, which are warnings" do
            expect(log_for("PLACE 0,0,NORTH\nLEFT\nPLACE 1,1,EAST\nREPORT\nJUMP")).to eq([])
        end

        it "keeps warnings and the log apart" do
            warnings = StringIO.new
            log = StringIO.new
            described_class.new("MOVE\nJUMP\nPLACE 0,0,NORTH", output: StringIO.new, warnings: warnings, log: log).run
            expect(warnings.string).to eq(%(warning: line 2: ignored (unknown command "JUMP")\n))
            expect(log.string).to eq("line 1: ignored (robot is not placed)\n")
        end
    end

    describe "input" do
        it "accepts any case, extra whitespace and CRLF line endings" do
            expect(run("place 1,2,east\r\n\n  Move \nlEfT\nmove\nreport")).to eq(["2,3,NORTH"])
        end

        it "streams: reads one line at a time from any object with each_line" do
            lines_read = 0
            source = Object.new
            source.define_singleton_method(:each_line) do |&block|
                return to_enum(:each_line) unless block

                ["PLACE 0,0,NORTH\n", "REPORT\n", "MOVE\n"].each { |l| lines_read += 1; block.call(l) }
            end
            expect(run(source)).to eq(["0,0,NORTH"])
            expect(lines_read).to eq(3)
        end

        it "writes to stdout by default" do
            expect { described_class.new("PLACE 0,0,NORTH\nREPORT").run }.to output("0,0,NORTH\n").to_stdout
        end
    end
end
