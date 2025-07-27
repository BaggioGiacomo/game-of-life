class GamesController < ApplicationController
  def new
    @game = Game.new(size: game_size || 30)
  end

  private

    def game_size
      params[:size].to_i if params[:size].present?
    end
end
