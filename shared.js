;(() => {
  // Get the real mode from a selected mode. Anything other than "light" or "dark" is treated as
  // "system" mode.
  const rrfGetRealMode = (selectedMode) => {
    if (selectedMode === "light" || selectedMode === "dark") {
      return selectedMode
    }

    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      return "dark"
    }

    return "light"
  }

  // Set the mode, given a "selected" mode.
  const rrfSetSelectedMode = (selectedMode) => {
    // Anything except "light" or "dark" is casted to "system".
    if (selectedMode !== "light" && selectedMode !== "dark") {
      selectedMode = "system"
    }

    // Store selected mode in `localStorage`.
    localStorage.setItem("rrfMode", selectedMode)

    // Set the mode selector to the selected mode.
    const modeComponent = document.getElementById("rrfModeComponent")
    if (modeComponent) {
      let labelHTML
      modeComponent.querySelectorAll("button[data-rrf-mode-value]").forEach((el) => {
        if (el.getAttribute("data-rrf-mode-value") === selectedMode) {
          el.classList.add("active")
          labelHTML = el.querySelector("i").outerHTML.replace("ms-2", "me-1")
        } else {
          el.classList.remove("active")
        }
      })
      modeComponent.querySelector("button[data-bs-toggle]").innerHTML = labelHTML
    }

    // Get the real mode to use.
    realMode = rrfGetRealMode(selectedMode)

    // Set the `realMode` effects.
    if (realMode === "light") {
      document.querySelectorAll(".rrf-light-mode").forEach((el) => {
        el.disabled = false
      })
      document.querySelectorAll(".rrf-dark-mode").forEach((el) => {
        el.disabled = true
      })
      document.querySelectorAll(".rrf-mode").forEach((el) => {
        el.setAttribute("data-bs-theme", "light")
      })
    } else if (realMode === "dark") {
      document.querySelectorAll(".rrf-light-mode").forEach((el) => {
        el.disabled = true
      })
      document.querySelectorAll(".rrf-dark-mode").forEach((el) => {
        el.disabled = false
      })
      document.querySelectorAll(".rrf-mode").forEach((el) => {
        el.setAttribute("data-bs-theme", "dark")
      })
    } else {
      console.log(`RRF: Unknown mode: ${mode}`)
    }
  }

  // Initialize dark/light mode before page fully loads to prevent flash.
  rrfSetSelectedMode(localStorage.getItem("rrfMode"))

  // Initialize dark/light mode after page load (mostly so mode component is updated).
  document.addEventListener("DOMContentLoaded", (event) => {
    rrfSetSelectedMode(localStorage.getItem("rrfMode"))

    // Also set up mode selector.
    document.querySelectorAll("#rrfModeComponent button[data-rrf-mode-value]").forEach((el) => {
      el.addEventListener("click", (event) => {
        rrfSetSelectedMode(event.target.getAttribute("data-rrf-mode-value"))
      })
    })
  })

  // Handle case where user changes system theme.
  if (window.matchMedia) {
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
      const selectedMode = localStorage.getItem("rrfMode")
      if (selectedMode !== "light" && selectedMode !== "dark") {
        rrfSetSelectedMode("system")
      }
    })
  }
})()
