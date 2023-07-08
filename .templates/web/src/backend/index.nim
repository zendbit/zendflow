{.used.}
import zfcore/server
import zfplugs/zview

var page {.threadvar.}: ZView

##  check if manifest.json exists in www
var manifest {.threadvar.}: JsonNode
let manifestFile = "wwww".joinPath("manifest.json")
if manifestFile.fileExists:
    manifest = parseFile(manifestFile)

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  before:
    page = newViewFromFile("index.mustache")
    page.c["siteUrl"] = siteUrl
    page.c["appVersion"] = getAppFilename().extractFilename

    if manifest.isNil:
      page.c["appName"] = manifest{"name"}.getStr

  get "/index.html":
    Http200.respHtml(page.render())
