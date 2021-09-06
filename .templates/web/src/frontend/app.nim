include karax/prelude
import random

proc createDom(): VNode =
  result = buildHtml(tdiv):
    if rand(100) <= 50:
      text "Hello World!"
    else:
      text "Hello Universe"
    text "This example using karax(spa nim framework), see karax repository for more documentations."
    br()
    a(href = "https://github.com/karaxnim/karax"):
      text "https://github.com/karaxnim/karax"

randomize()
setRenderer createDom

