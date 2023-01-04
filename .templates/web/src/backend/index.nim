{.used.}
import zfcore/server
import zfplugs/layout

var page {.threadvar.}: Layout

##  check if manifest.json exists in www
var manifest {.threadvar.}: JsonNode
let manifestFile = "wwww".joinPath("manifest.json")
if manifestFile.fileExists:
    manifest = parseFile(manifestFile)

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  before:
    page = newLayoutFromFile("index.mustache")
    page.c["siteUrl"] = siteUrl
    page.c["appVersion"] = getAppFilename().extractFilename

    if manifest.isNil:
      page.c["appName"] = manifest{"name"}.getStr

  get "/index.html":
    Http200.respHtml(page.render())
