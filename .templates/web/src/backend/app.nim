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
import index

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
      ##  check if current request if from allowed origin
      ##  check againts allowedOrigin list from settings.json
      let allowedOrigin = jSettings{"allowedOrigin"}
      if not allowedOrigin.isNil and
        request.url.getDomain in allowedOrigin.to(seq[string]):
        ##  set the allowr origin header to allow current domain request
          response.headers["Access-Control-Allow-Origin"] = request.url.getDomain
          response.headers["Access-Control-Allow-Credentials"] = "true"

emitServer()
