class Game
  attr_reader :grid, :width, :height, :changes

  def initialize(width: 30, height: 30, grid: nil)
    @width = width
    @height = height
    @grid = grid || Game.empty_grid(width, height)
    @changes = []
  end

  class << self
    def empty_grid(width, height)
      Array.new(height) { Array.new(width, false) }
    end

    def from_params(grid_params)
      return nil unless grid_params.is_a?(Array) && !grid_params.empty?

      height = grid_params.length
      width = grid_params.first&.length || 0

      # Validate that all rows have the same length
      return nil unless grid_params.all? { |row| row.length == width }

      new(width: width, height: height, grid: grid_params)
    end

    def from_living_cells(width, height, living_cells)
      grid = empty_grid(width, height)
      living_cells.each do |row, col|
        grid[row][col] = true if row < height && col < width
      end
      new(width: width, height: height, grid: grid)
    end
  end

  def next_generation
    new_grid = Game.empty_grid(width, height)
    changes = []

    (0...height).each do |row|
      (0...width).each do |col|
        alive_neighbors = count_alive_neighbors(row, col)
        current_cell = @grid[row][col]
        new_state = will_be_alive?(current_cell, alive_neighbors)

        new_grid[row][col] = new_state
        changes << { row:, col:, alive: new_state } if current_cell != new_state
      end
    end

    game = Game.new(width: @width, height: @height, grid: new_grid)
    game.instance_variable_set(:@changes, changes)
    game
  end

  def living_cells
    cells = []
    (0...height).each do |row|
      (0...width).each do |col|
        cells << [ row, col ] if @grid[row][col]
      end
    end
    cells
  end

  # Convenience method for square grids
  def self.square(size: 30, grid: nil)
    new(width: size, height: size, grid:)
  end

  private

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
      row >= 0 && row < height && col >= 0 && col < width
    end

    NEIGHBOR_OFFSETS = [
      [ -1, -1 ], [ -1, 0 ], [ -1, 1 ],
      [ 0, -1 ],           [ 0, 1 ],
      [ 1, -1 ],  [ 1, 0 ],  [ 1, 1 ]
    ].freeze
end
