{.used.}
import zfcore/server
import zfplugs/layout

var page {.threadvar.}: Layout
page = newLayoutFromFile("index.mustache")

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  before:
    page.c["siteUrl"] = siteUrl
    page.c["appVersion"] = getAppFilename().extractFilename

  get "/index/<id>":
    page.c["user"] = params.getOrDefault("id")
    Http200.respHtml(page.render())