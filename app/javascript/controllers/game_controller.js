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
          const cell = this.#findCell(change.row, change.col);
          if (cell) {
            cell.setAttribute(
              "data-cell-state",
              change.alive ? "alive" : "dead"
            );
          }
        });
        break;

      case "cell_toggled":
        const cell = this.#findCell(data.row, data.col);
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
    this.#showPauseButton();

    const speed = parseInt(this.speedInputTarget.value);

    this.subscription.perform("start_game", {
      grid: this.#getCurrentGrid(),
      speed: speed,
    });
  }

  pause() {
    this.isPlaying = false;
    this.#showStartButton();
    this.subscription.perform("stop_game");
  }

  resizeGrid() {
    if (this.isPlaying) this.pause();

    let width = parseInt(this.widthInputTarget.value);
    let height = parseInt(this.heightInputTarget.value);

    width = Math.max(10, Math.min(100, width));
    height = Math.max(10, Math.min(100, height));

    this.widthInputTarget.value = width;
    this.heightInputTarget.value = height;

    const livingCells = this.#getLivingCells();

    fetch(`/game/resize`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/vnd.turbo-stream.html",
      },
      body: JSON.stringify({
        width: width,
        height: height,
        living_cells: livingCells,
      }),
    })
      .then((response) => response.text())
      .then((html) => {
        Turbo.renderStreamMessage(html);
      });
  }

  resetGrid() {
    if (this.isPlaying) this.pause();

    const cells = this.gridTarget.querySelectorAll("[data-cell]");
    cells.forEach((cell) => {
      cell.setAttribute("data-cell-state", "dead");
    });
  }

  #getCurrentGrid() {
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

  #getLivingCells() {
    const livingCells = [];
    const cells = this.gridTarget.querySelectorAll("[data-cell]");

    cells.forEach((cell) => {
      if (cell.getAttribute("data-cell-state") === "alive") {
        const row = parseInt(cell.getAttribute("data-row"));
        const col = parseInt(cell.getAttribute("data-col"));
        livingCells.push([row, col]);
      }
    });

    return livingCells;
  }

  #findCell(row, col) {
    return this.gridTarget.querySelector(
      `[data-row="${row}"][data-col="${col}"]`
    );
  }

  #showStartButton() {
    this.playButtonTarget.textContent = "Start";
    this.playButtonTarget.classList.remove("bg-blue-600", "hover:bg-blue-700");
    this.playButtonTarget.classList.add("bg-green-600", "hover:bg-green-700");
  }

  #showPauseButton() {
    this.playButtonTarget.textContent = "Pause";
    this.playButtonTarget.classList.remove(
      "bg-green-600",
      "hover:bg-green-700"
    );
    this.playButtonTarget.classList.add("bg-blue-600", "hover:bg-blue-700");
  }
}
