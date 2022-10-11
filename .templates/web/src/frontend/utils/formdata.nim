import ffi

proc newFormData*(): JsObject {.importcpp: "new FormData()", nodecl.}
proc newFormData*(form: JsObject): JsObject {.importcpp: "new FormData(#)", nodecl.}
