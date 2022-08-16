{.used.}
import zfcore/server
import zfplugs/layout

var page {.threadvar.}: Layout
page = newLayoutFromFile("home.mustache")

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  get "/index/<id>":
    page.c["user"] = params.getOrDefault("id")
    Http200.respHtml(page.render())
