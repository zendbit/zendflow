import ffi

import strformat
import tables

type
  Css* = ref object
    styleList: OrderedTable[string, seq[string]]

proc newCss*(): Css =
  result = Css(
    styleList: initOrderedTable[string, seq[string]]()
  )

proc addStyle*(self: Css, k: string, val: seq[string]): Css {.discardable.} =
  if self.styleList.hasKey(k):
    self.styleList[k] = self.styleList[k] & val
  
  else:
    self.styleList[k] = val
  
  result = self

proc updateStyle*(self: Css, k: string, val: seq[string]): Css {.discardable.} =
  self.styleList[k] = val
  result = self

proc deleteStyle*(self: Css, k: string): Css {.discardable.} =
  self.styleList.del(k)
  result = self

proc getStyle*(self: Css, k: string): seq[string] =
  if self.styleList.hasKey(k):
    result = self.styleList[k]

proc `$`(self: Css): string =
  var styleList: seq[string] = @[]
  for k, v in self.styleList:
    styleList.add(
      k &
      "{" &
      v.join("; ") &
      "}"
    )

  result = styleList.join("")

proc applyCss*(self: Css) =
  let styleElements = jDocument.getElementsByTagName("style")
  var fragment = jDocument.toJs.createDocumentFragment()
  if styleElements.length.toInt == 0:
    let style = jDocument.createElement("style")
    style.innerText = ($self).cstring
    jDocument.getElementsByTagName("head")[0].appendChild(style)

  else:
    styleElements[0].innerText = ($self).cstring

