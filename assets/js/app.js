// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.delayedShow(200))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

import { SVG } from '../vendor/svg.3.1.2.esm.min.js'
window.SVG = SVG

// Taken almost verbatim from https://github.com/svgdotjs/svg.easing.js/blob/3afb24c3acfdb2a492c93da2dfcc5b394aec360d/src/svg.easing.js
function easeSwingTo(pos) {
    var s = 1.70158 + 1.0
    return (pos -= 1) * pos * ((s + 1) * pos + s) + 1
}

window.addEventListener(`phx:make-move`, (e) => {
    let svgGameGrid = SVG("svg#game-grid")

    for (let t of e.detail.transitions) {
        let elem = svgGameGrid.findOne(`use[data-col="${t.x}"][data-row="${t.y}"]`)
        switch (t.kind) {
            case "shift":
                elem.animate({ duration: 100 }).ease(">").move(t.xTo * 10, t.yTo * 10)
                break;

            case "appear":
                elem = makeCell(t.n, t.x, t.y).addTo(svgGameGrid)
                elem.transform({ scale: 0.1 })
                elem.animate({ duration: 100, delay: 150 }).transform({ scale: 1 })
                break;

            case "merge":
                elem = makeCell(t.n, t.xTo, t.yTo).addTo(svgGameGrid)
                elem.transform({ scale: 0.1 }).attr({ opacity: 0 })
                elem.animate({ duration: 200, delay: 50 }).ease(easeSwingTo).transform({ scale: 1 }).attr({ opacity: 1 })
                break;
        }
    }
})

function makeCell(n, col, row) {
    let x = col * 10
    let y = row * 10
    return SVG("<use/>").attr({
        href: `#cell-${n}`,
        x: x,
        y: y,
        transformOrigin: `${x + 4.75} ${y + 4.75}`
    })
}
