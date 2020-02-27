import dom
import jsffi

# import the document object and the console
#var document {.importc, nodecl.}: JsObject
#var console {.importc, nodecl.}: JsObject
# jsffi to initVue wrapper in index.html
proc vue(selector: JsObject): JsObject {.importcpp: "initVue(#)".}

export dom
export jsffi
export vue
