import
  init,
  jsffi,
  json,
  dom,
  strutils,
  uri3

var lastVisitedPage: string

proc lvInit*(lv: JsObject) =
  toJs(window)["LiveView"] = lv

proc lvInstance*(): JsObject =
  return toJs(window)["LiveView"]

proc lvAction*(p: JsonNode = JsonNode()) =
  lvInstance().send($ p)

proc lvVisitPage*(target: string, params: JsonNode = JsonNode()) =
  let queryString = parseUri3(target).getQueryString()
  if queryString != "":
    window.location.hash = ("#" & queryString).cstring

  lvAction(%*{"action": "visitPage", "target": target, "params": params})

  lastVisitedPage = target

proc lvUpdateState*(params: JsonNode = JsonNode()) =
  lvAction(%*{"action": "updateState", "params": params})

proc lvCurrentPage*(): string =
  return replace($window.location.href, "#", "")

proc lvLastVisitedPage*(): string =
  return lastVisitedPage
