class Game
  attr_reader :grid, :size

  def initialize(size: 30, grid: nil)
    @size = size
    @grid = grid || Game.empty_grid(size)
  end

  class << self
    def empty_grid(size)
      Array.new(size) { Array.new(size, false) }
    end

    def from_params(grid_params)
      return nil unless grid_params.is_a?(Array) && !grid_params.empty?

      size = grid_params.length
      new(size: size, grid: grid_params)
    end
  end

  def next_generation
    new_grid = Array.new(rows) { Array.new(cols, false) }

    (0...rows).each do |row|
      (0...cols).each do |col|
        alive_neighbors = count_alive_neighbors(row, col)
        current_cell = @grid[row][col]

        new_grid[row][col] = will_be_alive?(current_cell, alive_neighbors)
      end
    end

    self.class.new(size: @size, grid: new_grid)
  end

  private

    def rows
      @grid.length
    end

    def cols
      @grid[0].length
    end

    def will_be_alive?(current_state, neighbor_count)
      if current_state
        neighbor_count == 2 || neighbor_count == 3
      else
        neighbor_count == 3
      end
    end

    def count_alive_neighbors(row, col)
      NEIGHBOR_OFFSETS.count do |dr, dc|
        neighbor_row = row + dr
        neighbor_col = col + dc

        in_bounds?(neighbor_row, neighbor_col) && @grid[neighbor_row][neighbor_col]
      end
    end

    def in_bounds?(row, col)
      row >= 0 && row < rows && col >= 0 && col < cols
    end

    NEIGHBOR_OFFSETS = [
      [ -1, -1 ], [ -1, 0 ], [ -1, 1 ],
      [ 0, -1 ],           [ 0, 1 ],
      [ 1, -1 ],  [ 1, 0 ],  [ 1, 1 ]
    ].freeze
end
