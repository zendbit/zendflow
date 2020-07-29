import distros, os

when defined release:
  if detectOs(Windows):
    discard execShellCmd("start" & getAppDir().joinPath("appName_srv.exe"))
    discard execShellCmd("start " & getAppDir().joinPath("appName_wv.exe"))
  else:
    discard execShellCmd(getAppDir().joinPath("appName_srv &"))
    discard execShellCmd(getAppDir().joinPath("appName_wv &"))
else:
  if detectOs(Windows):
    discard execShellCmd(getAppDir().joinPath("appName_srv.exe"))
  else:
    discard execShellCmd(getAppDir().joinPath("appName_srv"))