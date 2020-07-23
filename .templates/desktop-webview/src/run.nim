import os

when defined windows:
  discard execShellCmd("start appName.exe")
else:
  discard execShellCmd("appName &")
