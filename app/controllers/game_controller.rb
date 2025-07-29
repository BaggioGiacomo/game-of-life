class GameController < ApplicationController
  def new
    if params[:living_cells].present?
      living_cells = JSON.parse(params[:living_cells]).map { |cell| [ cell["row"], cell["col"] ] }
      @game = Game.from_living_cells(grid_width, grid_height, living_cells)
    else
      @game = Game.new(width: grid_width, height: grid_height)
    end
  end

  def next_generation
    game = Game.from_params(params[:grid])

    if game
      new_game = game.next_generation
      render_grid_update(new_game.grid)
    else
      head :unprocessable_entity
    end
  end

  def resize
    living_cells = params[:living_cells] || []
    game = Game.from_living_cells(params[:width].to_i, params[:height].to_i, living_cells)
    render_grid_update game.grid
  end

  private

    def grid_width
      return 50 unless params[:width].present?
      params[:width].to_i.clamp(10, 100)
    end

    def grid_height
      return 30 unless params[:height].present?
      params[:height].to_i.clamp(10, 100)
    end

    def render_grid_update(grid)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "game-grid",
            partial: "game/grid",
            locals: { grid: grid }
          )
        end
      end
    end
end
