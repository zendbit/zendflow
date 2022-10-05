include karax/prelude

proc createDom(): VNode =
  result = buildHtml(tdiv):
    text "This is render using karax (single page application framework) for nim."
    br()
    a(href = "https://github.com/karaxnim/karax"):
      text "https://github.com/karaxnim/karax"

setRenderer createDom
