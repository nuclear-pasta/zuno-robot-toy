require_relative "./table"

class Robot
    attr_reader :x, :y, :facing, :table

    def initialize(x, y, facing, table)
        @x = x
        @y = y
        @facing = facing
        @table = table
    end

    def report
        "#{x},#{y},#{facing}"
    end
end
