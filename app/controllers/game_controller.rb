class GameController < ApplicationController
  def new
    @game = Game.new(size: game_size || 30)
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

  private

    def game_size
      params[:size].to_i if params[:size].present?
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
