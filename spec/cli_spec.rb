require_relative "../lib/cli"

RSpec.describe CLI do
    # CLI writes through $stdout and $stderr, so they are stubbed as spies:
    # nothing is printed, and each example asserts which lines were written.
    before do
        allow($stdout).to receive(:puts)
        allow($stderr).to receive(:puts)
    end

    def run_cli(*argv)
        described_class.new(argv).run
    end

    # Makes $stdin deliver these lines, as if they were typed or piped in.
    def stdin_lines(*lines)
        allow($stdin).to receive(:each_line).and_return(lines.map { |line| "#{line}\n" }.each)
    end

    def fixture(name)
        File.expand_path("fixtures/#{name}", __dir__)
    end

    describe "input" do
        it "reads commands from a file" do
            expect(run_cli(fixture("place_move_report.txt"))).to eq(0)
            expect($stdout).to have_received(:puts).with("0,1,NORTH")
        end

        it "reads commands from stdin when no file is given" do
            stdin_lines("PLACE 0,0,NORTH", "MOVE", "REPORT")
            expect(run_cli).to eq(0)
            expect($stdout).to have_received(:puts).with("0,1,NORTH")
        end
    end

    describe "invalid lines" do
        it "warns on stderr, keeps going, and still exits 0" do
            stdin_lines("PLACE 0,0,NORTH", "REPORT", "JUMP", "MOVE", "REPORT")
            expect(run_cli).to eq(0)
            expect($stdout).to have_received(:puts).with("0,0,NORTH").ordered
            expect($stdout).to have_received(:puts).with("0,1,NORTH").ordered
            expect($stderr).to have_received(:puts).with(%(warning: line 3: ignored (unknown command "JUMP")))
        end
    end
end
