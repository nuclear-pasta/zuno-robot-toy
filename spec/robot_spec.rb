require_relative "../lib/robot"

RSpec.describe Robot do
    let(:table) { Table.new(4, 4) }

    def robot_at(x, y, facing)
        described_class.new(x, y, facing, table)
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
