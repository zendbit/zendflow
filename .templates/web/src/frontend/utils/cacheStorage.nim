import ffi

##  This module contains wrapper for the CacheStorage for service worker
proc storageOpen*(name: cstring): Future[JsObject] {.importc: "caches.open", async.}
proc storageDelete*(name: cstring): Future[bool] {.importc: "caches.delete", async.}
proc storageHas*(name: cstring): Future[bool] {.importc: "caches.has", async.}
proc storageKeys*(name: cstring): Future[seq[cstring]] {.importc: "caches.keys", async.}
proc storageMatch*(request: JsObject, options: JsObject = nil): Future[JsObject] {.importc: "caches.match", async.}

##  This is cached storage manipulation after storage open operation
##  this operation for cache resutl of Promise the storageOpen
proc cacheAdd*(request: JsObject): Future[JsObject] {.importc: "cache.add", async.}
proc cacheAddAll*(requests: seq[JsObject]): Future[JsObject] {.importc: "cache.addAll", async.}
proc cacheDelete*(name: cstring): Future[bool] {.importc: "cache.delete", async.}
proc cacheMatch*(request: JsObject, options: JsObject = nil): Future[JsObject] {.importc: "cache.match", async.}
proc cacheMatchAll*(request: JsObject = nil, options: JsObject = nil): Future[seq[JsObject]] {.importc: "cache.matchAll", async.}
proc cachePut*(request: JsObject, response: JsObject): Future[JsObject] {.importc: "cache.put", async.}
