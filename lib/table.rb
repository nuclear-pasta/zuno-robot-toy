class Table
    class InvalidBound < StandardError; end

    # max_x / max_y are inclusive: Table.new(4, 4) is a 5x5 grid.
    attr_reader :max_x, :max_y

    def initialize(max_x, max_y)
        validate_bound!(:max_x, max_x)
        validate_bound!(:max_y, max_y)
        @max_x = max_x
        @max_y = max_y
    end

    def valid_position?(x, y)
        position_problem(x, y).nil?
    end

    # nil when x,y is on the table, otherwise why it is not.
    def position_problem(x, y)
        problems = [axis_problem("x", x, max_x), axis_problem("y", y, max_y)].compact
        return nil if problems.empty?

        "position #{x.inspect},#{y.inspect} is not on the table: #{problems.join(", ")}"
    end

    private

    def axis_problem(name, value, max)
        return "#{name} must be an integer, got #{value.inspect}" unless value.is_a?(Integer)
        return nil if value.between?(0, max)

        "#{name} must be between 0 and #{max}"
    end

    def validate_bound!(name, value)
        return if value.is_a?(Integer) && value >= 0

        raise InvalidBound, "#{name} must be a non-negative integer, got #{value.inspect}"
    end
end
