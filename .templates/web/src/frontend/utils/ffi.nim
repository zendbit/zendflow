import asyncjs
import jsffi
import jscore
import dom
import jsconsole

import strutils
import sequtils

export asyncjs
export jsffi
export jscore
export dom
export jsconsole
export strutils
export sequtils

var document {.importc, nodecl.}: JsObject
var window {.importc, nodecl.}: JsObject
var console {.importc, nodecl.}: JsObject
var UIkit* {.importc, nodecl.}: JsObject

var jDocument* = document.toJs
var jWindow* = document.toJs
var jConsole* = console.toJs

##  this for parsing and checking
proc isNaN*(obj: JsObject): bool {.importc, nodecl.}
proc parseInt*(s: cstring): JsObject {.importc, nodecl.}
proc parseFloat*(s: cstring): JsObject {.importc, nodecl.}
proc fromJson*(s: cstring): JsAssoc[cstring, cstring] {.importcpp: "JSON.parse(#)", nodecl.}
proc toJson*(obj: JsAssoc[cstring, cstring]): cstring {.importcpp: "JSON.stringify(#)", nodecl.}
proc selector*(s: cstring): JsObject {.importcpp: "document.querySelector(#)", nodecl.}
proc selector*(obj: JsObject): JsObject {.importcpp: "document.querySelector(#)", nodecl.}
proc selectorAll*(s: cstring): JsObject {.importcpp: "document.querySelectorAll(#)", nodecl.}
proc selectorAll*(obj: JsObject): JsObject {.importcpp: "document.querySelectorAll(#)", nodecl.}

proc toStr*(obj: JsObject): string =
  result = $(obj.to(cstring))

proc toStr*(obj: cstring): string =
  result = $obj

proc toInt*(s: cstring): BiggestInt =
  parseInt(s).to(BiggestInt)

proc toInt*(obj: JsObject): BiggestInt =
  obj.to(cstring).toInt

proc toFloat*(s: cstring): BiggestFloat =
  parseFloat(s).to(BiggestFloat)

proc toFloat*(obj: JsObject): BiggestFloat =
  obj.to(cstring).toFloat

proc newFragment*(doThing: proc (self: JsObject) = nil): JsObject =
  result = document.createDocumentFragment()

proc newElement*(
  name: string,
  class: seq[string] = @[],
  style: seq[string] = @[],
  attr: seq[(string, string)] = @[],
  doThing: proc (self: JsObject) = nil): JsObject =
  
  let elm = document.createElement(name)
  for c in class.mapIt(it.cstring):
    elm.classList.add(c)

  for s in style:
    let prop = s.split(":")
    elm.style[prop[0].cstring] = prop[1].strip().cstring

  for a in attr:
    elm.setAttribute(a[0].cstring, a[1].cstring)

  if not doThing.isNil:
    doThing(elm)

  result = elm

proc clearChild*(elm: JsObject) =
  while elm.hasChildNodes().to(bool):
    elm.removeChild(elm.firstChild)

proc childContent*(elm: JsObject, content: JsObject) =
  elm.clearChild()
  elm.appendChild(content)
