{.used.}
import zfcore/server
import zfplugs/layout

type
  Index* = ref object

proc render*(self: Index, user: string): string =
  let lyt = newLayoutFromFile("index.mustache")
  lyt.c["user"] = user
  result = lyt.render

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  get "/index/<id>":
    Http200.respHtml(Index().render(params.getOrDefault("id")))
