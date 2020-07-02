import
  init,
  jObj,
  liveview,
  strutils,
  strformat,
  json,
  ../pages/setup/setupPageJs,
  uri3

#[
# example call the jquery
# and append to the document body
jq(document.body).append(
  """
  <div id="app">
    {{ message }}
  </div>
  """)

# example using the vue js
# to interact with the layout
var a = newJObj()
  .add("el", "#app")
  .add("data", newJObj()
    .add("message", "Hello Vue"))
discard vue(a)

jq(document.body).append(document.body).append(
  """
  <div id="app-2">
  <span v-bind:title="message">
    Hover your mouse over me for a few seconds
    to see my dynamically bound title!
  </span>
  </div>
  """)

var b = newJObj()
  .add("el", "#app-2")
  .add("data", newJObj()
    .add("message", DateTime().toString()))
discard vue(b)

jq(document.body).append(document.body).append(
  """
  <div id="app-3">
    <span v-if="seen">Now you see me</span>
  </div>
  """)

var c = newJObj()
  .add("el", "#app-3")
  .add("data", newJObj()
    .add("seen", true))
discard vue(c)

jq(document.body).append(document.body).append(
  """
  <div id="app-4">
  <ol>
    <li v-for="todo in todos">
    {{ todo.text }}
    </li>
  </ol>
  </div>
  """)

var d = newJObj()
  .add("el", "#app-4")
  .add("data", newJObj()
    .add("todos", @[
      newJObj().add("text", "Learn nim"),
      newJObj().add("text", "Hack the nim")]))
discard vue(d)

jq(document.body).append(document.body).append(
  """
  <div id="app-5">
    <p>{{ message }}</p>
    <button v-on:click="reverseMessage">Reverse Message</button>
  </div>
  """)

var e = newJObj()
  .add("el", "#app-5")
  .add("data", newJObj()
    .add("message", "Hello vue from nim"))
  .add("methods", newJObj()
    .add("reverseMessage", proc (): cstring =
      let s = "Hello vue from nim".split(" ")
      var reverse: seq[string] = @[]
      for i in countdown(high(s), 0):
          reverse.add(s[i])
      return join(reverse, " ").cstring))
discard vue(e)

# also can call the console log from here :-)
console.log(e.methods.reverseMessage())

jq(document.body).append("<p>Test</p>")

# example call the ready state of the jquery
jq(document).ready(proc() =
  echo "ready state")
]#
var heartbeatInterval: JsObject
let wnd = toJs(window)

proc heartbeatCheck(cb: proc ()) =
  wnd.clearInterval(heartbeatInterval)
  heartbeatInterval = wnd.setInterval(cb, 5000)

proc initLV() =
  if isNil(lvInstance()) or lvInstance().readyState.to(cint) == 3:
    lvInit(newWS("ws://localhost:8080/liveview"))
    let lv = lvInstance()
    lv.onopen = proc (evt: JsObject) =
      wnd.toastr.success("Connected")
      if lvLastVisitedPage() != lvCurrentPage():
        lvVisitPage(lvCurrentPage())
      heartbeatCheck(initLV)

    lv.onmessage = proc (evt: JsObject) =
      let msg = parseJson($evt.data.to(cstring))
      let url = parseUri3(msg{"params"}{"url"}.getStr())

      case msg{"action"}.getStr()
      of "updateUI":
        let target = msg{"target"}.getStr()
        let ui = msg{"ui"}.getStr()
        jq(&"#{target}").html(ui.cstring)

        case url.getPathSegment(0)
        of "setup":
          setupPageJs.updateUI(url)
        else:
          discard

      of "updateState":
        case url.getPathSegment(0)
        of "setup":
          setupPageJs.updateState(url, msg{"params"})

      else:
        discard

    lv.onclose = proc (evt: JsObject) =
      heartbeatCheck(initLV)
      wnd.toastr.error("Connection loss, reconnecting...")

jq(document).ready(proc() =
  initLV()
  )
