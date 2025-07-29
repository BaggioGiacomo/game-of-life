import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="game"
export default class extends Controller {
  static targets = ["grid", "speedInput", "playButton"];

  connect() {
    this.isPlaying = false;
    this.intervalId = null;
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId);
  }

  toggleCell(event) {
    event.target.setAttribute(
      "data-cell-state",
      event.target.getAttribute("data-cell-state") === "alive"
        ? "dead"
        : "alive"
    );
  }

  togglePlay() {
    if (this.isPlaying) {
      this.#pause();
    } else {
      this.#start();
    }
  }

  #start() {
    this.isPlaying = true;
    this.playButtonTarget.textContent = "Pause";
    this.playButtonTarget.classList.remove(
      "bg-green-600",
      "hover:bg-green-700"
    );
    this.playButtonTarget.classList.add("bg-blue-600", "hover:bg-blue-700");

    const speed = parseInt(this.speedInputTarget.value);
    this.intervalId = setInterval(() => {
      this.#getNextGeneration();
    }, speed);
  }

  #pause() {
    this.isPlaying = false;
    this.playButtonTarget.textContent = "Start";
    this.playButtonTarget.classList.remove("bg-blue-600", "hover:bg-blue-700");
    this.playButtonTarget.classList.add("bg-green-600", "hover:bg-green-700");

    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  async #getNextGeneration() {
    const grid = this.#getCurrentGrid();
    const response = await fetch("/game/next_generation", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/vnd.turbo-stream.html",
      },
      body: JSON.stringify({ grid: grid }),
    });

    if (response.ok) {
      const turboStream = await response.text();
      Turbo.renderStreamMessage(turboStream);
    } else {
      console.error("Failed to fetch next generation:", response.statusText);
    }
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
}
