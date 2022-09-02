include ffi

type
  Blob* = ref object
    blob: JsObject

proc instance*(self: Blob): JsObject =
  result = self.blob

proc blobObj(
  l: openArray[cstring],
  o:  JsObject): JsObject {.importcpp: "new Blob(@)", nodecl.}

proc newBlob*(
  l: openArray[cstring],
  o: cstring = ""): Blob =
  let opts = newJsObject()
  opts["type".cstring] = o
  result = Blob(blob: blobObj(l, opts))

proc arrayBuffer*(
  self: Blob,
  doThing: proc (res: JsObject)) =
  self.blob.arrayBuffer().then(doThing)

proc text*(
  self: Blob,
  doThing: proc (res: JsObject)) =
  self.blob.text().then(doThing)

proc stream*(self: Blob): JsObject =
  result.blob = self.blob.stram()

proc slice*(self: Blob): Blob =
  result = newBlob(["".cstring])
  result.blob = self.blob.slice()
  result.blob["type"] = self.blob["type"]

proc slice*(
  self: Blob,
  start: int): Blob =
  result = newBlob(["".cstring])
  result.blob = self.blob.slice(start)
  result.blob["type"] = self.blob["type"]

proc slice*(
  self: Blob,
  start: int,
  stop: int): Blob =
  result = newBlob(["".cstring])
  result.blob = self.blob.slice(start, stop)
  result.blob["type"] = self.blob["type"]

proc slice*(
  self: Blob,
  start: int,
  stop: int,
  contentType: cstring): Blob =
  result = newBlob(["".cstring])
  result.blob = self.blob.slice(start, stop, contentType)
  result.blob["type"] = self.blob["type"]


let blob = newBlob(["hello".cstring], "text/plain")