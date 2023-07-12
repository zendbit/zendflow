##
##  zfcore web framework for nim language
##  This framework if free to use and to modify
##  License: BSD
##  Author: Amru Rosyada
##  Email: amru.rosyada@gmail.com
##  Git: https://github.com/zendbit
##

## import zfcore
import zfcore/server
#import example
import zfplugs/settings
import index/action as indexAction

##  shared settings as threadvar
var jSettings {.threadvar.}: JsonNode

routes:
  staticDir "/"

  before:
    ##  set settings value before routing
    jSettings = jsonSettings()

  after:
    ##  check if settings is exists
    if not jSettings.isNil:
      ##  check if access from same origin
      let allowedOrigin = jSettings{"allowedOrigin"}
      let requestDomain = &"{request.url.getScheme}://{request.url.getDomain}"
      if not allowedOrigin.isNil and
        request.url.getDomain in allowedOrigin.to(seq[string]):
          response.headers["Access-Control-Allow-Origin"] = requestDomain
          response.headers["Access-Control-Allow-Credentials"] = "true"
          response.headers["Vary"] = "Origin"

emitServer()
