import dom, jsffi, jscore, jsconsole, asyncjs, strformat, strutils, sequtils
export dom, jsffi, jscore, jsconsole, asyncjs, strformat, strutils, sequtils
import uri3

proc newXMLHttpRequest*(): JsObject {.importcpp: "new XMLHttpRequest()".}

proc createHtmlNode*(html: cstring): Node =
  let parent = document.createElement("div")
  parent.innerHtml = html
  result = parent.children[0]

proc reloadHash*(target: cstring) =
  window.location.hash = ""
  window.location.hash = ($target).replace("#", "").cstring

proc addEvent*(et: EventTarget, ev: cstring, cb: proc (e: Event)) =
  et.removeEventListener(ev, cb)
  et.addEventListener(ev, cb)

proc uriHashParts*(uriStr: string = ""): tuple[path: cstring, pathSegments: JsObject, query: JsObject, queryString: cstring] =
  var uriStr = uriStr

  if uriStr == "":
    uriStr = $window.location.hash

  let uri = uriStr.replace("#", "/").parseUri3
  let hashParts = uri.getPathSegments().join("/")
  let qs = newJsObject()

  for q in uri.getAllQueries():
    qs[q[0].cstring] = q[1].cstring

  result = (hashparts.cstring, uri.getPathSegments().toJs(), qs, uri.getQueryString().cstring)
