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

    describe "--verbose" do
        it "also logs discarded commands to stderr, keeping reports on stdout" do
            stdin_lines("MOVE", "JUMP", "PLACE 0,0,NORTH", "REPORT")
            expect(run_cli("-v")).to eq(0)
            expect($stdout).to have_received(:puts).with("0,0,NORTH")
            expect($stderr).to have_received(:puts).with("line 1: ignored (robot is not placed)")
            expect($stderr).to have_received(:puts).with(%(warning: line 2: ignored (unknown command "JUMP")))
        end

        it "logs nothing without the flag, and is accepted after the file" do
            run_cli(fixture("early_commands_then_place.txt"))
            expect($stderr).not_to have_received(:puts)

            run_cli(fixture("early_commands_then_place.txt"), "--verbose")
            expect($stderr).to have_received(:puts).with("line 1: ignored (robot is not placed)")
        end
    end

    describe "--help" do
        it "prints usage to stdout with -h or --help, exits 0 and runs nothing" do
            stdin_lines("PLACE 0,0,NORTH", "REPORT")
            %w[-h --help].each { |flag| expect(run_cli(flag)).to eq(0) }
            expect($stdout).to have_received(:puts)
                .with(a_string_including("Usage: ruby main.rb", "--verbose", "--help")).twice
            expect($stdout).not_to have_received(:puts).with("0,0,NORTH")
            expect($stderr).not_to have_received(:puts)
        end
    end

    describe "usage errors (exit 2)" do
        it "rejects an unknown option and more than one file" do
            expect(run_cli("--bogus")).to eq(2)
            expect($stderr).to have_received(:puts)
                .with(a_string_including("invalid option: --bogus"), a_string_including("Usage:"))

            expect(run_cli("a.txt", "b.txt")).to eq(2)
            expect($stderr).to have_received(:puts)
                .with(a_string_including("too many arguments"), a_string_including("Usage:"))
        end
    end

    describe "unreadable input (exit 1)" do
        it "reports a missing file or a directory without a stack trace" do
            expect(run_cli("/nope/missing.txt")).to eq(1)
            expect($stderr).to have_received(:puts).with(/\AError: No such file or directory/)

            expect(run_cli(fixture(""))).to eq(1)
            expect($stderr).to have_received(:puts).with(/\AError: Is a directory/)
        end
    end
end
