import std/jsffi

# import the document object and the console
var document {.importc, nodecl.}: JsObject
var console {.importc, nodecl.}: JsObject

# JavaScript calls, when no corresponding proc exists for `JsObject`.
proc main*() =
  console.log("Hello JavaScript!")
