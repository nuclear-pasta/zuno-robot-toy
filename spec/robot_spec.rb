require_relative "../lib/robot"

RSpec.describe Robot do
    let(:table) { Table.new(4, 4) }

    def robot_at(x, y, facing)
        described_class.new(x, y, facing, table)
    end

    describe "#move" do
        it "moves one step in the direction it faces, keeping its facing" do
            { "NORTH" => [2, 3], "EAST" => [3, 2], "SOUTH" => [2, 1], "WEST" => [1, 2] }.each do |facing, (x, y)|
                robot = robot_at(2, 2, facing)
                expect(robot.move).to be true
                expect([robot.x, robot.y, robot.facing]).to eq([x, y, facing])
            end
        end

        it "never falls off: at each edge it stays put and returns false" do
            { "NORTH" => [2, 4], "EAST" => [4, 2], "SOUTH" => [2, 0], "WEST" => [0, 2] }.each do |facing, (x, y)|
                robot = robot_at(x, y, facing)
                expect(robot.move).to be false
                expect([robot.x, robot.y]).to eq([x, y])
            end
        end

        it "respects the size of its table" do
            robot = described_class.new(0, 0, "EAST", Table.new(1, 1))
            2.times { robot.move }
            expect(robot.report).to eq("1,0,EAST")
        end
    end

    describe "#initialize" do
        it "starts at the given position and facing" do
            robot = robot_at(2, 3, "WEST")
            expect([robot.x, robot.y, robot.facing]).to eq([2, 3, "WEST"])
        end
    end

    describe "#report" do
        it "returns x,y,facing" do
            expect(robot_at(1, 2, "EAST").report).to eq("1,2,EAST")
        end
    end
end
