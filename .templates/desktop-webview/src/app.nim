import webview.app as wv
import server.app as sv

asyncCheck sv.runServer()
asyncCheck wv.runWebview()
