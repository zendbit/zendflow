import macros
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

var document* {.importc, nodecl.}: JsObject
var self* {.importc, nodecl.}: JsObject
#var window* {.importc, nodecl.}: JsObject
#var navigator* {.importc, nodecl.}: JsObject
#var console* {.importc, nodecl.}: JsObject
var UIkit* {.importc, nodecl.}: JsObject

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

proc setClass*(j: JsObject, class: seq[cstring]) =
  for c in class:
    j.classList.add(c)

proc removeClass*(j: JsObject, class: seq[cstring]) =
  for c in class:
    j.classList.remove(c)

proc replaceClass*(j: JsObject, class: seq[tuple[oldClass: cstring, newClass: cstring]]) =
  for c in class:
    j.classList.replace(c.oldClass, c.newClass)

proc toggleClass*(j: JsObject, class: cstring) =
  j.classList.toggle(class)

proc toggleClass*(j: JsObject, class: cstring, condition: bool) =
  j.classList.toggle(class, condition)

proc setStyle*(j: JsObject, style: seq[tuple[name: cstring, val: cstring]]) =
  for s in style:
    j.style[s.name] = s.val

proc removeStyle*(j: JsObject, style: seq[cstring]) =
  for s in style:
    j.style.removeProperty(s)

proc setAttr*(j: JsObject, attr: seq[tuple[name: cstring, val: cstring]]) =
  for a in attr:
    j.setAttribute(a.name, a.val)

proc removeAttr*(j: JsObject, attr: seq[cstring]) =
  for a in attr:
    j.removeAttribute(a)

proc newElement*(
  name: cstring,
  class: seq[cstring] = @[],
  style: seq[tuple[name: cstring, val: cstring]] = @[],
  attr: seq[tuple[name: cstring, val: cstring]] = @[],
  doThing: proc (self: JsObject) = nil): JsObject =
  
  let elm = document.createElement(name)
  elm.setClass(class)
  elm.setStyle(style)
  elm.setAttr(attr)

  if not doThing.isNil:
    doThing(elm)

  result = elm

proc clearChild*(elm: JsObject) =
  while elm.hasChildNodes().to(bool):
    elm.removeChild(elm.firstChild)

proc childContent*(elm: JsObject, content: JsObject) =
  elm.clearChild()
  elm.appendChild(content)

macro Fragment*(t: untyped): untyped =
  discard


