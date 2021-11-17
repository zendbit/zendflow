{.used.}
import zfcore/server
import zfplugs/layout

type
  Home* = ref object

proc index*(self: Home, user: string): string =
  let lyt = newLayoutFromFile("templates".joinPath("home.mustache"))
  lyt.c["user"] = user
  result = lyt.render

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  get "/home/<id>":
    Http200.respHtml(Home().index(params.getOrDefault("id")))
