import threadpool
import webview/app as wv
import server/app as sv

# start server in separate thread
# only run with webview if in release build
# if not just run server as ordinary web apps for easy debugging with browser
if defined(release):
  spawn sv.runServer(zfcoreInstance)
  wv.runWebview()
else:
  sv.runServer(zfcoreInstance)
