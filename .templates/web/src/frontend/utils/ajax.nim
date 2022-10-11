import ffi
import blob

type
  Ajax* = ref object
    xhr: JsObject
    progress*: proc (e: Event)
    load*: proc (e: Event)
    error*: proc (e: Event)
    abort*: proc (e: Event)
    loadstart*: proc (e: Event)
    loadend*: proc (e: Event)
    readystatechange*: proc (e: Event)
    timeout*: proc (e: Event)

proc xhrObj(): JsObject {.importcpp: "new XMLHttpRequest()", nodecl.}

proc instance*(self: Ajax): JsObject =
  result = self.xhr

proc newAjax*(
  progress: proc (e: Event) = nil,
  load: proc (e: Event) = nil,
  error: proc (e: Event) = nil,
  abort: proc (e: Event) = nil,
  loadstart: proc (e: Event) = nil,
  loadend: proc (e: Event) = nil,
  readystatechange: proc (e: Event) = nil,
  timeout: proc (e: Event) = nil): Ajax =

  result = Ajax(
    xhr: xhrObj(),
    progress: progress,
    load: load,
    error: error,
    abort: abort,
    loadstart: loadstart,
    loadend: loadend,
    readystatechange: readystatechange,
    timeout: timeout
  )

  if not result.xhr.isNil:
    if not result.progress.isNil:
      result.xhr.addEventListener("progress", result.progress)

    if not result.load.isNil:
      result.xhr.addEventListener("load", result.load)

    if not result.error.isNil:
      result.xhr.addEventListener("error", result.error)

    if not result.abort.isNil:
      result.xhr.addEventListener("abort", result.abort)

    if not result.loadend.isNil:
      result.xhr.addEventListener("loadend", result.loadend)
    
    if not result.timeout.isNil:
      result.xhr.addEventListener("timeout", result.loadend)

proc abort*(self: Ajax) =
  self.xhr.abort()

proc getAllResponseHeaders*(self: Ajax): cstring =
  result = self.xhr.getAllResponseHeaders().to(cstring)

proc getResponseHeader*(
  self: Ajax,
  header: cstring): cstring =
  result = self.xhr.getResponseHeader(header).to(cstring)

proc open*(
  self: Ajax,
  methodType: cstring,
  url: cstring,
  async: bool = true,
  user: cstring = "",
  password: cstring = "") =
  if user != "" and password != "":
    self.xhr.open(methodType, url, async, user, password)

  else:
    self.xhr.open(methodType, url, async)

proc send*(
  self: Ajax,
  data: cstring) =
  self.xhr.send(data)

proc send*(
  self: Ajax,
  data: blob.Blob) =
  self.xhr.send(data.instance)

proc overrideMimeType*(
  self: Ajax,
  mimeType: cstring) =
  self.xhr.overrideMimeType(mimeType)

proc setRequestHeader*(
  self: Ajax,
  header: cstring,
  value: cstring) =
  self.xhr.setRequestHeader(header, value)

