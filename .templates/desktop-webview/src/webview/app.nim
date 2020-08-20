import strutils, strformat, json
import zfplugs/settings, webview
import distros, os

#
# the webview using webview wrapper
# see https://github.com/oskca/webview for the webview documentation
#
#
# start the webview using current configuration
# point to the local server 127.0.0.1:port/index.html
#
var wv = newWebView("My App", &"""http://127.0.0.1:{jsonSettings()["port"].getInt}/index.html""")
wv.run()

if detectOs(Windows):
  discard execShellCmd("""taskkill /IM "appName_srv.exe" /F""")
else:
  discard execShellCmd("""killall appName_srv""")
