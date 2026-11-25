require_relative "./table"
require_relative "./directions"

class Robot
    class Error < StandardError; end
    class InvalidRotation < Error; end

    attr_reader :x, :y, :facing, :table

    def initialize(x, y, facing, table)
        @x = x
        @y = y
        @facing = facing
        @table = table
    end

    # Returns false, without moving, if the move would fall off the table.
    def move
        delta_x, delta_y = Directions::VECTORS[facing]
        next_x = x + delta_x
        next_y = y + delta_y

        return false unless table.valid_position?(next_x, next_y)

        @x = next_x
        @y = next_y
        true
    end

    def report
        "#{x},#{y},#{facing}"
    end

    def rotate(rotation)
        step = Directions::ROTATION_TO_STEP.fetch(rotation) do
            raise InvalidRotation, "#{rotation.inspect} is not one of #{Directions::ROTATIONS.join(", ")}"
        end
        current_index = Directions::DIRECTION_TO_VALUE[facing]
        new_index = (current_index + step) % Directions::DIRECTIONS.size
        @facing = Directions::DIRECTION_TO_VALUE.key(new_index)
    end
end
