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

    describe "#rotate" do
        it "turns LEFT counter-clockwise and RIGHT clockwise" do
            { "NORTH" => "WEST", "WEST" => "SOUTH", "SOUTH" => "EAST", "EAST" => "NORTH" }.each do |from, to|
                robot = robot_at(0, 0, from)
                robot.rotate("LEFT")
                expect(robot.facing).to eq(to)
            end
            { "NORTH" => "EAST", "EAST" => "SOUTH", "SOUTH" => "WEST", "WEST" => "NORTH" }.each do |from, to|
                robot = robot_at(0, 0, from)
                robot.rotate("RIGHT")
                expect(robot.facing).to eq(to)
            end
        end

        it "does not change position" do
            robot = robot_at(1, 2, "NORTH")
            robot.rotate("LEFT")
            expect([robot.x, robot.y]).to eq([1, 2])
        end

        it "refuses an unknown rotation and keeps its facing" do
            robot = robot_at(0, 0, "NORTH")
            ["BACK", "left", nil].each do |rotation|
                expect { robot.rotate(rotation) }.to raise_error(Robot::InvalidRotation, /is not one of RIGHT, LEFT/)
            end
            expect(robot.facing).to eq("NORTH")
        end
    end

    describe "#initialize" do
        it "starts at the given position and facing" do
            robot = robot_at(2, 3, "WEST")
            expect([robot.x, robot.y, robot.facing]).to eq([2, 3, "WEST"])
        end

        it "refuses a position off the table, saying why" do
            [[5, 0], [0, -1], [9, 9]].each do |x, y|
                expect { robot_at(x, y, "NORTH") }
                    .to raise_error(Robot::InvalidPlacement, /\Aposition #{x},#{y} is not on the table: /)
            end
        end

        it "refuses a position that is not an integer" do
            expect { robot_at(1.5, 0, "NORTH") }.to raise_error(Robot::InvalidPlacement, /x must be an integer, got 1\.5/)
        end

        it "refuses anything but the four direction names" do
            ["UP", "north", nil, ""].each do |facing|
                expect { robot_at(0, 0, facing) }.to raise_error(Robot::InvalidDirection, /is not one of NORTH, EAST/)
            end
        end

        it "uses error classes that share Robot::Error" do
            [Robot::InvalidPlacement, Robot::InvalidDirection, Robot::InvalidRotation]
                .each { |error| expect(error).to be < Robot::Error }
        end
    end

    describe "#report" do
        it "returns x,y,facing" do
            expect(robot_at(1, 2, "EAST").report).to eq("1,2,EAST")
        end
    end
end
