class GameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:game_id]
    stream_from "game_#{@game_id}_#{current_user.id}"
  end

  def unsubscribed
    stop_game
  end

  def start_game(data)
    stop_game

    @game = Game.from_params(data["grid"], data["generationNumber"] || 0)
    return if @game.nil?

    @speed = data["speed"].to_i.clamp(100, 1000)
    @running = true

    @game_thread = Thread.new do
      while @running
        sleep(@speed / 1000.0)

        next_game = @game.next_generation
        ActionCable.server.broadcast(
          "game_#{@game_id}_#{current_user.id}",
          {
            action: "update_cells",
            changes: next_game.changes,
            generation_number: next_game.generation_number
          }
        )

        @game = next_game
      end
    rescue => e
      Rails.logger.error "Game thread error: #{e.message}"
    ensure
      @running = false
    end
  end

  def stop_game
    @running = false
    @game_thread&.join(0.1)
    @game_thread = nil
  end
end
