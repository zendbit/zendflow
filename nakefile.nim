import
  nake,
  os,
  strutils,
  strformat,
  json,
  osproc

let cmdLineParams = commandLineParams()
var cmdParams: seq[string]
var cmdOptions: seq[string]
for clp in cmdLineParams:
  if clp.startsWith("-"):
    cmdOptions.add(clp)
  else:
    cmdParams.add(clp)

var appsDir = "apps"

const
  jsonNakefile = "nakefile.json"
  nakefile = "nakefile.nim"
  consoleAppDir = joinPath(".templates", "console")
  webAppDir = joinPath(".templates", "web")
  nimdepsDir = ".nimdeps"

proc loadJsonNakeFile(appName: string = ""): JsonNode =
  result = %*{"jsonNakeFile": ""}
  try:
    if appName == "" and existsFile(jsonNakefile):
      let tmp = parseFile(jsonNakefile)
      if tmp{"jsonNakeFile"}.getStr() != "":
        result = parseFile(tmp{"jsonNakeFile"}.getStr())
      else:
        result = tmp
    else:
      result = parseFile(joinPath(appsDir, appName, jsonNakefile))
  except Exception:
    discard

proc isUmbrellaMode(showMsg: bool = false): bool =
  if not existsDir(".templates"):
    if showMsg:
      echo "Not in umbrella mode."
      echo "available command:"
      echo "nake build"
      echo "nake build-run"
      echo "nake release"
      echo "nake release-run"
      echo "nake run"
    result = false
    appsDir = ""
  else:
    # check if apps folder exist, if not create the dir
    discard existsOrCreateDir(appsDir)
    if not existsFile(jsonNakefile):
      let f = open(jsonNakefile, FileMode.fmWrite)
      f.write((%*{"jsonNakeFile": ""}).pretty())
      f.close()
    result = true

proc defaultApp(appName: string = ""): tuple[appName: string, appType: string] =
  let jsonNake = loadJsonNakeFile(appName)
  if appName != "":
    let f = open(jsonNakefile, FileMode.fmWrite)
    f.write((%*{"jsonNakeFile": joinPath(appsDir, appName, jsonNakefile)}).pretty(2))
    f.close()

  return (
      jsonNake{"appInfo"}{"appName"}.getStr(),
      jsonNake{"appInfo"}{"appType"}.getStr())

proc isAppExist(appName: string): bool =
  return existsDir(joinPath(appsDir, appName)) and
    existsFile(joinPath(appsDir, appName, jsonNakefile))

proc build(appName:string, appType:string, release: bool = false): bool =
  if not isAppExist(appName) and isUmbrellaMode():
      echo &"app {appName} doesn't exist."
      return false

  var appDir = joinPath(appsDir, appName)
  var appSrc = joinPath(appDir, "src")

  if not isUmbrellaMode():
    appDir = ""
    appSrc = "src"

  case appType
  of "web":
    var buildParams = @[
      "nim", "c", "-d:ssl",
      &"""-o:{joinPath(appDir, appName & "App")}""",
      joinPath(appSrc, "server", appName & "App.nim")]

    var buildJsParams = @[
          "nim", "js",
          &"""-o:{joinPath(appDir, "www", "private", "js", "compiled", appName & "App.js")}""",
          joinPath(appSrc, "spa", appName & "App.nim")]

    if release:
      buildParams.insert("-d:release", 2)
      buildJsParams.insert("-d:release", 2)
    else:
      buildParams.insert("-o:nimDebugDlOpen", 2)

    if execCmd(join(buildParams, " ")) == 0:
      if execCmd(join(buildJsParams, " ")) == 0:
        result = true

  of "console":
    var buildParams = @[
      "nim", "c",
      &"""-o:{joinPath(appDir, appName & "App")}""",
      joinPath(appSrc, appName & "App.nim")]

    if release:
      buildParams.insert("-d:release", 2)
    else:
      buildParams.insert("-o:nimDebugDlOpen", 2)

    if execCmd(join(buildParams, " ")) == 0:
      result = true

  else:
    echo &"no action for app with type {appType}."

proc installDeps(appName: string) =
  let nimble = loadJsonNakeFile(appName){"nimble"}
  shell("nimble update")
  for pkg in nimble:
    let pkgName = pkg.getStr().replace("install ", "").replace("develop ", "")
    let (_, exitCode) = execCmdEx(@["nimble", "path", "\"" & pkgName & "\""].join(" "))
    if exitCode > 0:
      echo "Trying get latest " & pkgName
      shell(@["cd", nimdepsDir, "&&", "nimble", pkg.getStr()].join(" "))
    elif pkg.getStr().strip().startsWith("develop"):
      let pkgDir = joinPath(nimdepsDir, pkgName)
      echo "Trying get latest " & pkgName & " -> " & pkgDir
      shell(@["cd", pkgDir, "&&", "git", "pull"].join(" "))

proc run(appName: string) =
  if not isUmbrellaMode():
    shell(joinPath(".", (@[appName & "App"] & cmdOptions).join(" ")))
  else:
    shell(joinPath(appsDir, appName, (@[appName & "App"] & cmdOptions).join(" ")))

proc newApp(appName: string, appType: string) =
  let appDir = joinPath(appsDir, appName)
  let appSrcDir = joinPath(appsDir, appName, "src")

  if isAppExist(appName):
    echo &"App {appName} already exist."
    return

  case appType
  of "console":
    copyDir(consoleAppDir, appDir)
    copyFile(nakefile, joinPath(appDir, nakefile))
    moveFile(
      joinPath(appSrcDir, "app.nim"),
      joinPath(appSrcDir, appName & "App.nim"))
  of "web":
    copyDir(webAppDir, appDir)
    copyFile(nakefile, joinPath(appDir, nakefile))
    let wwwDir = joinPath(appDir, "www")
    let jsCompiledDir = joinPath(wwwDir, "private", "js", "compiled")
    if not existsDir(jsCompiledDir):
      createDir(jsCompiledDir)
    for appSrc in ["server", "spa"]:
      let webSrcDir = joinPath(appSrcDir, appSrc)
      let appChangedName = joinPath(webSrcDir, appName & "App.nim")
      moveFile(
        joinPath(webSrcDir, "app.nim"),
        appChangedName)
      if appSrc == "spa":
        let outJs = joinPath(jsCompiledDir, appName & "App.js")
        let outIndexHtml = joinPath(wwwDir, "index.html")
        if shell("karun", appChangedName):
          moveFile(appName & "App.js", outJs)
          moveFile(appName & "App.html", outIndexHtml)
          var f = open(outIndexHtml, FileMode.fmRead)
          let outHtml = f.readAll().replace(appName & "App.js",
            outJs.replace(wwwDir))
          f.close()
          f = open(outIndexHtml, FileMode.fmWrite)
          f.write(outHtml)
          f.close()
  else:
    echo "app template not found."

  if existsDir(appDir):
    let jsonNake = loadJsonNakeFile(appName)
    jsonNake["appInfo"]["appName"] = %appName
    open(joinPath(appDir, jsonNakefile), FileMode.fmWrite).write(jsonNake.pretty())
    echo &"app {appName} created."

task "new", "create new app. Ex: nake new console.":
  if not isUmbrellaMode(true):
    return

  if cmdParams.len() > 2:
    let appName = cmdParams[2]
    let appType = cmdParams[1]
    newApp(appName, appType)

  else:
    echo "invalid new command arguments."

task "default-app", "get/set default app. Ex: nake default-app [appname].":
  if not isUmbrellaMode(true):
    return

  if cmdParams.len() > 1:
    let defApp = defaultApp(cmdParams[1])
    if not isAppExist(defApp.appName):
      echo &"app {defApp.appName} doesn't exist."
    else:
      echo &"default app changed to {defApp.appName}."
  else:
    echo defaultApp()

task "build", "build app, Ex: nake build [appname].":
  let defApp = defaultApp()

  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    let appType = loadJsonNakeFile(appName){"appInfo"}{"appType"}.getStr()
    discard build(appName, appType)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    discard build(defApp.appName, defApp.appType)

  else:
    echo "invalid build arguments."

task "release", "release app, Ex: nake release [appname].":
  let defApp = defaultApp()
  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    let appType = loadJsonNakeFile(appName){"appInfo"}{"appType"}.getStr()
    discard build(appName, appType, true)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    discard build(defApp.appName, defApp.appType, true)

  else:
    echo "invalid build arguments."

task "run", "run app, ex: nake run [appname].":
  let defApp = defaultApp()
  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    run(appName)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    run(defApp.appName)

  else:
    echo "invalid run arguments."

task "build-run", "build and then run the app. Ex: nake build-run [appname].":
  let defApp = defaultApp()
  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    let appType = loadJsonNakeFile(appName){"appInfo"}{"appType"}.getStr()
    if build(appName, appType):
      run(appName)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    if build(defApp.appName, defApp.appType):
      run(defApp.appName)

  else:
    echo "invalid run arguments."

task "release-run", "release and then run the app. Ex: nake release-run [appname].":
  let defApp = defaultApp()
  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    let appType = loadJsonNakeFile(appName){"appInfo"}{"appType"}.getStr()
    if build(appName, appType, true):
      run(appName)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    if build(defApp.appName, defApp.appType, true):
      run(defApp.appName)

  else:
    echo "invalid run arguments."

task "list-apps", "show available app. Ex: nake list-app":
  if not isUmbrellaMode(true):
    return

  if existsDir(appsDir):
    for dir in walkDirs(joinPath(appsDir, "*")):
      if fileExists(joinPath(dir, jsonNakefile)):
        echo "-> " & extractFilename(dir)

task "delete-app", "delete app. Ex: nake delete-app appname.":
  if not isUmbrellaMode(true):
    return

  if cmdParams.len() > 1:
    let appDir = joinPath(appsDir, cmdParams[1])
    if existsDir(appDir):
      removeDir(appDir, true)
    if not existsDir(appDir):
      echo &"{appDir} deleted."
    else:
      echo &"fail to delete {appDir}."
  else:
    echo "invalid delete-app arguments."

task "install-deps", "install nimble app depedencies. Ex: nake install-deps [appname].":
  let defApp = defaultApp()
  if not existsDir(nimdepsDir):
    createDir(nimdepsDir)
  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    installDeps(appName)

  elif isAppExist(defApp.appName) or not isUmbrellaMode():
    installDeps(defApp.appName)

  else:
    echo "invalid run arguments."

task "help", "show available tasks. Ex: nake help.":
  shell("nake")
