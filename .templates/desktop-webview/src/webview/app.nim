import strutils, strformat, json
import zfplugs.settings, webview

#
# the webview using webview wrapper
# see https://github.com/oskca/webview for the webview documentation
#
proc runWebview*() =
  #
  # start the webview using current configuration
  # point to the local server 127.0.0.1:port/index.html
  #
  var wv = newWebView("My App", &"""http://127.0.0.1:{jsonSettings()["port"].getInt}/index.html""")
  wv.run()
