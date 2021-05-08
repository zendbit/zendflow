import karax/[karaxdsl, vdom]

proc default*(): string =
  let vnode = buildHtml(html):
    head:
      meta(content = "text/html;charset=utf-8", `http-equiv` = "Content-Type")
      meta(content = "utf-8", `http-equiv` = "encoding")
      meta(content = "widht=device-width,initial-scale=1", name = "viewport")
      title:
        text "Zendcraft"
    body(id = "body"):
      tdiv(id = "ROOT")
      script(type="text/javascript", src="private/js/compiled/zendcraft.js")

  result = $vnode

