require "stringio"
require_relative "../lib/command_runner"

RSpec.describe CommandRunner do
    # Runs the input and returns the REPORT lines that were written.
    def run(input, **options)
        output = StringIO.new
        described_class.new(input, output: output, **options).run
        output.string.lines.map(&:chomp)
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
