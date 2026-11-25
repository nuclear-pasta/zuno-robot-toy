require_relative "../lib/table.rb"

RSpec.describe Table do
    let(:table) { Table.new(4, 3) }

    describe "#valid_position?" do
        it "accepts the corners and the middle" do
            [[0, 0], [4, 3], [0, 3], [4, 0], [2, 2]].each do |x, y|
                expect(table.valid_position?(x, y)).to be(true), "expected #{x},#{y} to be valid"
            end
        end

        it "rejects positions off each side" do
            [[-1, 0], [0, -1], [5, 0], [0, 4], [5, 4]].each do |x, y|
                expect(table.valid_position?(x, y)).to be(false), "expected #{x},#{y} to be invalid"
            end
        end

        it "uses a separate bound for each axis" do
            expect(table.valid_position?(4, 4)).to be false
            expect(table.valid_position?(4, 3)).to be true
        end

        it "rejects anything that is not an integer" do
            expect(table.valid_position?(1.5, 1)).to be false
            expect(table.valid_position?(nil, 1)).to be false
            expect(table.valid_position?(1, "1")).to be false
        end
    end

    describe "#position_problem" do
        it "is nil for a position on the table" do
            expect(table.position_problem(2, 2)).to be_nil
        end

        it "names the bad axis and its valid range" do
            expect(table.position_problem(9, 2)).to eq("position 9,2 is not on the table: x must be between 0 and 4")
            expect(table.position_problem(5, 4))
                .to eq("position 5,4 is not on the table: x must be between 0 and 4, y must be between 0 and 3")
        end

        it "says when a coordinate is not an integer" do
            expect(table.position_problem(1.5, 1))
                .to eq("position 1.5,1 is not on the table: x must be an integer, got 1.5")
        end
    end

    describe "#initialize" do
        it "accepts non-negative integer bounds, zero included" do
            expect(Table.new(4, 4).max_x).to eq(4)
            expect { Table.new(0, 0) }.not_to raise_error
        end

        it "raises InvalidBound for a bad bound, naming it" do
            [-1, 1.5, "4", nil].each do |bad|
                expect { Table.new(bad, 4) }.to raise_error(Table::InvalidBound, /max_x/)
                expect { Table.new(4, bad) }.to raise_error(Table::InvalidBound, /max_y/)
            end
        end
    end
end
