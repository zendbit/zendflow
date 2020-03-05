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
proc vue*(jsObject: JsObject): JsObject {.importcpp: "initVue(#)".}
# Initialize the jquery
proc jq*(selector: JsObject): JsObject {.importcpp: "initJq(#)".}
proc jq*(selector: Element): JsObject {.importcpp: "initJq(#)".}
proc jq*(selector: Document): JsObject {.importcpp: "initJq(#)".}
proc jq*(): JsObject {.importcpp: "initJq()".}

export
    dom,
    jscore,
    asyncjs,
    jsffi
