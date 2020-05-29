import
  dom,
  jscore,
  asyncjs,
  jsffi

# import the document object and the console
#var document {.importc, nodecl.}: JsObject
var console* {.importc, nodecl.}: JsObject
# jsffi to initVue wrapper in index.html
# this map to function:
#
# Initialize the vue js
proc vue*(jsObject: JsObject): JsObject {.importcpp: "initVue(#)" discardable.}
# Initialize the jquery
proc jq*(selector: JsObject): JsObject {.importcpp: "jqSelector(#)" discardable.}
proc jq*(selector: Element): JsObject {.importcpp: "jqSelector(#)" discardable.}
proc jq*(selector: Document): JsObject {.importcpp: "jqSelector(#)" discardable.}
proc jq(selector: cstring): JsObject {.importcpp: "jqSelector(#)" discardable.}
proc jq*(): JsObject {.importcpp: "jq()" discardable.}
# initialize xHttpReq
proc xHttpReq*(): JsObject {.importcpp: "xHttpReq()" discardable.}
proc webSocket(host: cstring): JsObject {.importcpp: "webSocket(#)" discardable.}
proc eventSource(host: cstring): JsObject {.importcpp: "eventSource(#)" discardable.}

proc newWS*(host: string): JsObject =
  return webSocket(host.cstring)

proc newSSE*(host: string): JsObject =
  return eventSource(host.cstring)

proc jq*(selector: string): JsObject =
  return jq(selector.cstring)

export
  dom,
  jscore,
  asyncjs,
  jsffi
