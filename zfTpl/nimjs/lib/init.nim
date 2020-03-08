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
proc jq*(): JsObject {.importcpp: "jq()" discardable.}

export
    dom,
    jscore,
    asyncjs,
    jsffi
