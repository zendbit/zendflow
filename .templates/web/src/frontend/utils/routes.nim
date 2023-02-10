import ffi

import uri3

import strformat
import sequtils
import strutils
import tables

type
  RouteData* = ref object
    baseUrl*: cstring
    url*: cstring
    hash*: cstring
    uriSegments*: seq[cstring]
    hashSegments*: seq[cstring]
    queries*: Table[cstring, cstring]
    hashQueries*: Table[cstring, cstring]

proc locationToRouteData*(): RouteData =
  ##
  ##  conver location data into RouteData
  ##
  result = RouteData()
  
  let uri = parseURI3(window.location.href.toStr())
  result.baseUrl = uri.getBaseUrl.cstring
  result.hash = uri.getHash.cstring
  result.url = uri.getPath.cstring
  
  if result.url == "":
    result.url = "/"

  result.uriSegments = uri.getPathSegments().mapIt(it.cstring)
  result.hashSegments = filter(
    uri.getHashSegments, proc (s: string): bool =
      result = s != "" and s != "#"
  ).mapIt(it.cstring)

  result.queries = initTable[cstring, cstring]()
  for q in uri.getAllQueries:
    result.queries[q[0].cstring] = q[1].cstring
  
  result.hashQueries = initTable[cstring, cstring]()
  for q in uri.getAllHashQueries:
    result.hashQueries[q[0].cstring] = q[1].cstring

proc doRoutes*(r: proc (data: RouteData)) =
  ##
  ##  do routing to the callback proc
  ##  pass route data to the callback
  ##
  window.addEventListener(
    "hashchange", proc (ev: Event) =
      r(locationToRouteData())
  , false)

  window.addEventListener(
    "DOMContentLoaded", proc (ev: Event) =
      r(locationToRouteData())
  , false)
