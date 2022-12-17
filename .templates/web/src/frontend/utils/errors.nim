import ffi

import strformat

var errors: JsObject = newJsObject()

proc setError*(key: cstring, value: cstring) =
  errors[key] = value

proc getError*(key: cstring): cstring =
  console.log key
  result = errors[key].to(cstring)

proc delError*(key: cstring) =
  if not errors[key].isNil:
    discard errors[key].jsDelete

proc clearError*() =
  discard errors.jsDelete
  errors = newJsObject()

