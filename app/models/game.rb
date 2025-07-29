class Game
  attr_reader :grid, :size, :changes

  def initialize(size: 30, grid: nil)
    @size = size
    @grid = grid || Game.empty_grid(size)
    @changes = []
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
    new_grid = Game.empty_grid grid_size
    changes = []

    (0...rows).each do |row|
      (0...cols).each do |col|
        alive_neighbors = count_alive_neighbors(row, col)
        current_cell = @grid[row][col]
        new_state = will_be_alive?(current_cell, alive_neighbors)

        new_grid[row][col] = new_state
        changes << { row:, col:, alive: new_state } if current_cell != new_state
      end
    end

    game = Game.new(size: @size, grid: new_grid)
    game.instance_variable_set(:@changes, changes)
    game
  end

  def living_cells
    cells = []
    (0...rows).each do |row|
      (0...cols).each do |col|
        cells << [ row, col ] if @grid[row][col]
      end
    end
    cells
  end

  def self.from_living_cells(size, living_cells)
    grid = empty_grid(size)
    living_cells.each do |row, col|
      grid[row][col] = true if row < size && col < size
    end
    new(size: size, grid: grid)
  end

  private

    # Since the grid is square, we can use either dimension for rows and cols
    # I'll keep both methods if in the future I want to support non-square grids
    def rows
      grid_size
    end

    def cols
      grid_size
    end

    def grid_size
      @grid.length
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
