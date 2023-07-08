{.used.}
import zfcore/server
import zfplugs/zview

var page {.threadvar.}: ZView

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  before:
    page = newViewFromFile("index.mustache")
    page.c["siteUrl"] = siteUrl
    page.c["appVersion"] = getAppFilename().extractFilename

    if manifest.isNil:
      page.c["appName"] = manifest{"name"}.getStr

  get "/":
    respRedirect("/index")

  get "/index":
    Http200.respHtml(page.render())
