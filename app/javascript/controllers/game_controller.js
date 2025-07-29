import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

export default class extends Controller {
  static targets = [
    "grid",
    "speedInput",
    "playButton",
    "widthInput",
    "heightInput",
  ];

  connect() {
    this.isPlaying = false;
    this.gameId =
      this.element.dataset.gameId || Math.random().toString(36).substring(7);
    this.setupActionCable();
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  setupActionCable() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "GameChannel",
        game_id: this.gameId,
      },
      {
        received: (data) => {
          this.handleReceivedData(data);
        },
      }
    );
  }

  handleReceivedData(data) {
    switch (data.action) {
      case "update_cells":
        data.changes.forEach((change) => {
          const cell = this.findCell(change.row, change.col);
          if (cell) {
            cell.setAttribute(
              "data-cell-state",
              change.alive ? "alive" : "dead"
            );
          }
        });
        break;

      case "cell_toggled":
        const cell = this.findCell(data.row, data.col);
        if (cell) {
          cell.setAttribute("data-cell-state", data.state ? "alive" : "dead");
        }
        break;
    }
  }

  toggleCell(event) {
    if (this.isPlaying) return;

    const cell = event.target;
    const currentState = cell.getAttribute("data-cell-state") === "alive";
    const newState = !currentState;

    cell.setAttribute("data-cell-state", newState ? "alive" : "dead");
  }

  togglePlay() {
    if (this.isPlaying) {
      this.pause();
    } else {
      this.start();
    }
  }

  start() {
    this.isPlaying = true;
    this.showPauseButton();

    const speed = parseInt(this.speedInputTarget.value);

    this.subscription.perform("start_game", {
      grid: this.getCurrentGrid(),
      speed: speed,
    });
  }

  pause() {
    this.isPlaying = false;
    this.showStartButton();
    this.subscription.perform("stop_game");
  }

  getCurrentGrid() {
    const rows = this.gridTarget.querySelectorAll(".flex");
    const grid = [];

    rows.forEach((row) => {
      const rowData = [];
      row.querySelectorAll("[data-cell]").forEach((cell) => {
        rowData.push(cell.getAttribute("data-cell-state") === "alive");
      });
      grid.push(rowData);
    });

    return grid;
  }

  findCell(row, col) {
    return this.gridTarget.querySelector(
      `[data-row="${row}"][data-col="${col}"]`
    );
  }

  showStartButton() {
    this.playButtonTarget.textContent = "Start";
    this.playButtonTarget.classList.remove("bg-blue-600", "hover:bg-blue-700");
    this.playButtonTarget.classList.add("bg-green-600", "hover:bg-green-700");
  }

  showPauseButton() {
    this.playButtonTarget.textContent = "Pause";
    this.playButtonTarget.classList.remove(
      "bg-green-600",
      "hover:bg-green-700"
    );
    this.playButtonTarget.classList.add("bg-blue-600", "hover:bg-blue-700");
  }

  applyPreset(event) {
    const preset = event.target.value;
    if (!preset) return;

    const [width, height] = preset.split("x").map((n) => parseInt(n));

    this.widthInputTarget.value = width;
    this.heightInputTarget.value = height;
    this.widthInputTarget.form.submit();
  }
}
