/*******************************
 * START OF LIB/DOCS COMMON JS *
 *******************************/

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
    const modeComponent = document.getElementById("rrfModeComponent")

    // Anything except "light" or "dark" is casted to "system".
    if (selectedMode !== "light" && selectedMode !== "dark") {
      selectedMode = "system"
    }

    // Store selected mode in `localStorage`.
    localStorage.setItem("rrfMode", selectedMode)

    // Set the mode selector to the selected mode.
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

  // Initialize dark/light mode.
  document.addEventListener("DOMContentLoaded", (event) => {
    const selectedMode = localStorage.getItem("rrfMode")
    rrfSetSelectedMode(selectedMode)
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

/*****************************
 * END OF LIB/DOCS COMMON JS *
 *****************************/

document.addEventListener("DOMContentLoaded", () => {
  // Initialize `Highlight.js`.
  hljs.highlightAll()

  // Setup the floating table of contents.
  let table = "<ul>"
  let hlevel = 2
  let hprevlevel = 2
  document.querySelectorAll("h2, h3, h4").forEach((header) => {
    hlevel = parseInt(header.tagName[1])

    if (hlevel > hprevlevel) {
      table += "<ul>"
    } else if (hlevel < hprevlevel) {
      Array(hprevlevel - hlevel)
        .fill(0)
        .forEach(function () {
          table += "</ul>"
        })
    }
    table += `<li><a href="${
      header.querySelectorAll("a")[0].href
    }">${header.childNodes[0].nodeValue.trim()}</a></li>`
    hprevlevel = hlevel
  })
  if (hlevel > hprevlevel) {
    table += "</ul>"
  }
  table += "</ul>"
  if (table != "<ul></ul>") {
    document.getElementById("headersTable").innerHTML = table
  }
})
