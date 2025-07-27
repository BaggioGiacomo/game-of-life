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
  end
end
