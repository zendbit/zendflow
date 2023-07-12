{.used.}
import zfcore/server
import zfplugs/zview

var view {.threadvar.}: ZView

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  before:
    view = newViewFromFile("index.mustache")
    view.c["siteUrl"] = siteUrl
    view.c["appVersion"] = getAppFilename().extractFilename

  get "/":
    respRedirect("/index")

  get "/index":
    Http200.respHtml(view.render())
