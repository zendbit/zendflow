import karax/[karaxdsl, vdom]

proc render*(): string =
  let vnode = buildHtml(html()):
    head:
      meta(
        content = "width=device-width, initial-scale=1",
        name = "viewport")
      title: text "[appName]"
    body(
      id = "body",
      class="site"):
        tdiv(id = "ROOT")
        script(
          type = "text/javascript",
          src = "/private/js/compiled/[appName].js")

  result = $vnode
