class GameController < ApplicationController
  def new
    @game = Game.new(size: game_size)
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
      return 30 unless params[:size].present?

      params[:size].to_i.clamp(10, 70)
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
