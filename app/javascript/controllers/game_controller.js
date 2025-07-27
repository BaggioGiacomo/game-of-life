import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="game"
export default class extends Controller {
  connect() {}

  toggleCell(event) {
    event.target.setAttribute(
      "data-cell-state",
      event.target.getAttribute("data-cell-state") === "alive"
        ? "dead"
        : "alive"
    );
  }
}
