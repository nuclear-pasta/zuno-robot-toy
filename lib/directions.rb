module Directions
    DIRECTION_TO_VALUE = {
        "NORTH" => 0,
        "EAST" => 1,
        "SOUTH" => 2,
        "WEST" => 3
    }.freeze

    DIRECTIONS = DIRECTION_TO_VALUE.keys.freeze

    VECTORS = {
        "NORTH" => [0, 1],
        "EAST" => [1, 0],
        "SOUTH" => [0, -1],
        "WEST" => [-1, 0]
    }.freeze

    CLOCKWISE = 1
    COUNTERCLOCKWISE = -1

    ROTATION_TO_STEP = {
        "RIGHT" => CLOCKWISE,
        "LEFT" => COUNTERCLOCKWISE
    }.freeze

    ROTATIONS = ROTATION_TO_STEP.keys.freeze

    def self.valid?(direction)
        DIRECTIONS.include?(direction)
    end
end
