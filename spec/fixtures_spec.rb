require_relative "../lib/cli"

# Runs every sample file through the CLI, as `ruby main.rb --verbose spec/fixtures/NAME` does.
RSpec.describe "sample input files" do
    # Returns the exit status, the REPORT lines written to stdout, and the two
    # kinds of lines written to stderr: warnings (invalid lines) and the
    # --verbose log (valid commands that were discarded).
    def run_fixture(name)
        reports = []
        errors = []
        allow($stdout).to receive(:puts) { |*lines| reports.concat(lines) }
        allow($stderr).to receive(:puts) { |*lines| errors.concat(lines) }
        status = CLI.new(["--verbose", File.expand_path("fixtures/#{name}", __dir__)]).run
        warnings, logs = errors.partition { |line| line.start_with?("warning: ") }
        [status, reports, warnings, logs]
    end

    describe "the three example scenarios" do
        it "place_move_report.txt moves one step north" do
            status, reports, warnings, logs = run_fixture("place_move_report.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,1,NORTH"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end

        it "place_rotate_report.txt turns left to face west" do
            status, reports, warnings, logs = run_fixture("place_rotate_report.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,0,WEST"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end

        it "walk_and_turn.txt walks east, turns left and walks north" do
            status, reports, warnings, logs = run_fixture("walk_and_turn.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["3,3,NORTH"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end
    end

    describe "valid commands that cannot be carried out: logged, without a warning" do
        it "empty_file.txt reports nothing" do
            status, reports, warnings, logs = run_fixture("empty_file.txt")
            expect(status).to eq(0)
            expect(reports).to be_empty
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end

        it "report_before_place.txt reports nothing, as the robot is never placed" do
            status, reports, warnings, logs = run_fixture("report_before_place.txt")
            expect(status).to eq(0)
            expect(reports).to be_empty
            expect(warnings).to be_empty
            expect(logs).to eq([
                "line 1: ignored (robot is not placed)",
                "line 2: ignored (robot is not placed)",
                "line 3: ignored (robot is not placed)",
                "line 4: ignored (robot is not placed)"
            ])
        end

        it "early_commands_then_place.txt discards the commands before PLACE" do
            status, reports, warnings, logs = run_fixture("early_commands_then_place.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["1,1,SOUTH"])
            expect(warnings).to be_empty
            expect(logs).to eq([
                "line 1: ignored (robot is not placed)",
                "line 2: ignored (robot is not placed)"
            ])
        end

        it "place_off_table.txt discards each PLACE off the table and keeps the robot where it was" do
            status, reports, warnings, logs = run_fixture("place_off_table.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,0,NORTH", "0,0,NORTH"])
            expect(warnings).to be_empty
            expect(logs).to eq([
                "line 1: ignored (position 5,5 is not on the table: x must be between 0 and 4, y must be between 0 and 4)",
                "line 2: ignored (robot is not placed)",
                "line 5: ignored (position 9,9 is not on the table: x must be between 0 and 4, y must be between 0 and 4)"
            ])
        end

        it "replace_robot.txt places the robot again, and stops it at the east edge" do
            status, reports, warnings, logs = run_fixture("replace_robot.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,0,NORTH", "3,3,WEST", "2,3,WEST", "4,0,EAST"])
            expect(warnings).to be_empty
            expect(logs).to eq(["line 8: ignored (would fall off the table)"])
        end

        it "walk_into_every_edge.txt stops at each edge, then walks away from one" do
            status, reports, warnings, logs = run_fixture("walk_into_every_edge.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,0,WEST", "0,0,SOUTH", "4,4,NORTH", "4,4,EAST", "4,2,SOUTH"])
            expect(warnings).to be_empty
            expect(logs).to eq([
                "line 2: ignored (would fall off the table)",
                "line 5: ignored (would fall off the table)",
                "line 8: ignored (would fall off the table)",
                "line 11: ignored (would fall off the table)"
            ])
        end
    end

    describe "accepted forms, without a warning or a log line" do
        it "mixed_case.txt reads commands and directions in any case" do
            status, reports, warnings, logs = run_fixture("mixed_case.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["2,3,NORTH"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end

        it "whitespace_and_crlf.txt reads through blank lines, extra spaces, tabs and CRLF" do
            status, reports, warnings, logs = run_fixture("whitespace_and_crlf.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["2,2,EAST"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end

        it "no_final_newline.txt runs the last line without a newline" do
            status, reports, warnings, logs = run_fixture("no_final_newline.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,0,EAST"])
            expect(warnings).to be_empty
            expect(logs).to be_empty
        end
    end

    describe "invalid lines: each skipped with a warning, never logged" do
        it "garbage_lines.txt warns about its eight invalid lines and runs the two valid ones" do
            status, reports, warnings, logs = run_fixture("garbage_lines.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["1,1,NORTH"])
            expect(warnings).to eq([
                %(warning: line 1: ignored (unknown command "JUMP")),
                %(warning: line 2: ignored ("UP" is not one of NORTH, EAST, SOUTH, WEST)),
                %(warning: line 3: ignored (PLACE expects X,Y,DIRECTION but got "1,2")),
                %(warning: line 4: ignored (PLACE X and Y must be integers, got "a")),
                %(warning: line 5: ignored (PLACE expects X,Y,DIRECTION but got "1,2,NORTH,3")),
                %(warning: line 6: ignored (unknown command "PLACE1,1,NORTH")),
                %(warning: line 8: ignored (unknown command "MOVE 1")),
                %(warning: line 9: ignored (unknown command "REPORT now"))
            ])
            expect(logs).to be_empty
        end

        it "bad_bytes_in_one_line.txt warns about the line that is not valid UTF-8 and runs the rest" do
            status, reports, warnings, logs = run_fixture("bad_bytes_in_one_line.txt")
            expect(status).to eq(0)
            expect(reports).to eq(["0,1,NORTH"])
            expect(warnings).to eq([
                'warning: line 2: ignored (not valid UTF-8: "\xFF\xFE"; re-save the file as UTF-8)'
            ])
            expect(logs).to be_empty
        end
    end
end
