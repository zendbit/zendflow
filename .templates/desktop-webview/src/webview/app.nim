import strutils, strformat, json, asyncdispatch
export strutils, strformat, json, asyncdispatch
import zfplugs.settings, webview

#
# see https://github.com/oskca/webview for the webview documentation
#
proc runWebview*(): Future[void] {.async.} =
  var wv = newWebView("My App", &"""127.0.0.1:{jsonSettings["port"].getStr}/index.html""")
  wv.run()
