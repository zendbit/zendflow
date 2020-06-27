import
  nake,
  os,
  strutils,
  strformat,
  json,
  osproc,
  re

let cmdLineParams = commandLineParams()
var cmdParams: seq[string]
var cmdOptions: seq[string]
for clp in cmdLineParams:
  if clp.startsWith("-"):
    cmdOptions.add(clp)
  else:
    cmdParams.add(clp)

var appsDir = ""
var templatesDir = ""

const
  jsonNakefile = "nakefile.json"
  nakefile = "nakefile.nim"
  consoleAppDir = joinPath(".templates", "console")
  webAppDir = joinPath(".templates", "web")
  nimdepsDir = ".nimdeps"

# init appsDir and templatesDir
# depend on the top level of the nakefile.json
if existsFile(jsonNakefile):
  let jnode = parseFile(jsonNakefile)
  appsDir = jnode{"apps_dir"}.getStr().replace("::", $DirSep)
  templatesDir = jnode{"templates_dir"}.getStr().replace("::", $DirSep)

proc loadJsonNakefile(appName: string = ""): JsonNode =
  result = %*{}
  try:
    if existsFile(joinPath(appsDir, appName, jsonNakefile)):
      result = parseFile(joinPath(appsDir, appName, jsonNakefile))
    elif existsFile(jsonNakefile):
      result = parseFile(jsonNakefile)
  except Exception:
    discard

proc isUmbrellaMode(showMsg: bool = false): bool =
  if not existsDir(templatesDir):
    if showMsg:
      echo "Not in umbrella mode."
      echo "available command:"
      echo "nake debug"
      echo "nake debug-run"
      echo "nake release"
      echo "nake release-run"
      echo "nake run"
    result = false
  else:
    # check if apps folder exist, if not create the dir
    discard existsOrCreateDir(appsDir)
    if not existsFile(jsonNakefile):
      let f = open(jsonNakefile, FileMode.fmWrite)
      f.write((%*{
        "json_nakefile": "",
        "templates_dir": ".templates",
        "apps_dir": "apps"}).pretty())
      f.close()
    result = true

# this function will subtitute variable
# defined int the nakefile.json
# ex:
# {"foo": "hello", "bar": "{foo} world"}
# into {"foo": "hello", "bar": "hello world"}
proc subtituteVar(varnode: JsonNode): JsonNode =
  result = %*{}
  for k, v in varnode:
    var svar = v.getStr()
    for s in svar.findAll(re"{[\w\W]+}"):
      let svarname = s.replace("{", "").replace("}", "")
      let svarvalue = result{svarname}.getStr()
      if svarvalue == "":
        continue
      svar = svar.replace(s, svarvalue)

    result[k] = %svar

# this will remove leading or ending double colon
# ::hello::world::
# will transform to hello::world
proc cleanDoubleColon(str: string): string =
  result = str.strip()
  if result == "::" or result == "":
    result = ""
  else:
    if result.startsWith("::"):
      result = result.subStr(2, high(result))

    if result.endsWith("::"):
      result = result.subStr(0, high(result) - 2)

# will process action list
proc doActionList(actionList: JsonNode) =
  if not isNil(actionList) and actionList.kind == JsonNodeKind.JArray:
    for action in actionList:
      let actionType = action{"action"}.getStr()
      case actionType
      of "copy_dir", "copy_file", "move_file", "move_dir":
        let list = action{"list"}
        if not isNil(list):
          for l in list:
            let src = l{"src"}
            let dest = l{"dest"}
            if not isNil(src) and not isNil(dest):
              let src = src.getStr().cleanDoubleColon()
              let dest = dest.getStr().cleanDoubleColon()
              case actionType
              of "copy_dir":
                copyDir(src, dest)
              of "copy_file":
                copyFile(src, dest)
              of "move_file":
                moveFile(src, dest)
              of "move_dir":
                moveDir(src, dest)

      of "cmd":
        var exe = ""
        if not isNil(action{"exe"}):
          exe = action{"exe"}.getStr().cleanDoubleColon()

        var props = action{"props"}
        var options = ""
        if not isNil(action{"options"}):
          options = action{"options"}.getStr().cleanDoubleColon()

        if not isNil(props):
          props = subtituteVar(props)
          for k, v in props:
            let vstr = v.getStr().cleanDoubleColon()
            if exe != "":
              exe = exe.replace("{" & k & "}", vstr)

            if options != "":
              options = options.replace("{" & k & "}", vstr)

        var cmd: seq[string] = @[]
        if exe != "":
          cmd.add(exe)

        if options != "":
          cmd.add(options)

        let nextCmd = action{"next"}
        if not isNil(nextCmd) and nextCmd.len() != 0:
          echo cmd.join(" ")
          if execCmd(cmd.join(" ")) == 0:
            doActionList(nextCmd)

        elif cmd.len() != 0:
          shell(cmd.join(" "))

      of "replace_str":
        let file = action{"file"}
        let list = action{"list"}
        if not isNil(file) and
          not isNil(list) and
          existsFile(file.getStr()):
          var f = open(file.getStr(), FileMode.fmRead)
          var fstr = f.readAll()
          f.close()
          for l in list:
            let oldstr = l{"old"}
            let newstr = l{"new"}
            if not isNil(oldstr) and not isNil(newstr):
              fstr = fstr.replace(
                oldstr.getStr().cleanDoubleColon(),
                newstr.getStr().cleanDoubleColon())
              
          f = open(file.getStr(), FileMode.fmWrite)
          f.write(fstr)
          f.close()

      of "remove_file", "remove_dir", "create_dir":
        let list = action{"list"}
        if not isNil(list):
          for l in list:
            let lstr = l.getStr().cleanDoubleColon()
            case actionType
            of "remove_file":
              removeFile(lstr)

            of "remove_dir":
              removeDir(lstr)

            of "create_dir":
              createDir(lstr)

      else:
        echo "{actionType} action not implemented."

  else:
    echo "not valid action list, action list should be in json array."

proc defaultApp(): tuple[appName: string, appType: string] =
  var appname = ""
  var apptype = ""

  let jsonNake = loadJsonNakefile()
  if not isNil(jsonNake{"json_nakefile"}):
    let forwardJsonNakefile = jsonNake{"json_nakefile"}.getStr()
    if forwardJsonNakefile != "" and existsFile(forwardJsonNakefile):
      let jsonNake = parseFile(forwardJsonNakefile)
      appname = jsonNake{"appinfo"}{"appname"}.getStr()
      apptype = jsonNake{"appinfo"}{"apptype"}.getStr()
  
  else:
    appname = jsonNake{"appinfo"}{"appname"}.getStr()
    apptype = jsonNake{"appinfo"}{"apptype"}.getStr()

  return (appname, apptype)

proc setDefaultApp(appName: string): bool =
  let jsonNake = loadJsonNakefile()
  if not isNil(jsonNake{"json_nakefile"}):
    jsonNake["json_nakefile"] = %joinPath(appsDir, appName, jsonNakefile)
    let f = open(jsonNakefile, FileMode.fmWrite)
    f.write(jsonNake.pretty(2))
    f.close()
    result = true

proc currentAppDir(appName: string): string =
  result = "."
  if appsDir != "":
    result = joinPath(appsDir, appName)

proc isAppExists(appName: string): bool =
  result = existsDir(joinPath(appsDir, appName)) and
    existsFile(joinPath(appsDir, appName, jsonNakefile))

  # check if the jsonNakefile contains appinfo -> appname
  # this mean directly run from the app dir
  if not result:
    let jnake = loadJsonNakefile()
    if not isNil(jnake{"appinfo"}):
      result = not isNil(jnake{"appinfo"}{"appname"})

proc installDeps(appName: string) =
  let nimble = loadJsonNakefile(appName){"nimble"}
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

proc existsTemplates(templateName: string): bool =
  for kind, path in walkDir(templatesDir):
    if kind == PathComponent.pcDir and
      path.endsWith(DirSep & templateName):
      return true

# this will read from templates nakefile.json
# .templates/apptype/nakefile.json
# and will process init section
proc newApp(appName: string, appType: string) =
  let appDir = joinPath(appsDir, appName)

  if isAppExists(appName):
    echo &"App {appName} already exist."
    return

  if existsTemplates(appType):
    # load json from templates
    let fpath = joinPath(".templates", appType, jsonNakefile)
    if existsFile(fpath):
      let f = open(fpath, FileMode.fmRead)
      var fcontent = f.readAll().replace("{appname}", appName)
      f.close()

      var jnode = parseJson(fcontent)
      if not isNil(jnode):
        jnode["appinfo"]["appname"] = %appName
        jnode["appinfo"]["apptype"] = %appType
        fcontent = $jnode

        var varnode = jnode{"init_var"}
        if not isNil(varnode):
          varnode = subtituteVar(varnode)
          for k, v in varnode:
            fcontent = fcontent.replace("{" & k & "}", v.getStr())

        varnode = jnode{"appinfo"}
        if not isNil(varnode):
          varnode = subtituteVar(varnode)
          for k, v in varnode:
            fcontent = fcontent.replace("{" & k & "}", v.getStr())

        # replace templates and apps dir definition
        # this defined in the base nakefile.json
        fcontent = fcontent.replace("{templates_dir}", templatesDir)
        fcontent = fcontent.replace("{apps_dir}", appsDir)

        jnode = parseJson(fcontent)
        let initnode = jnode{"init"}
        if not isNil(initnode) and initnode.kind == JsonNodeKind.JArray:
          doActionList(parseJson(($initNode).replace("::", $DirSep)))
          
          if existsDir(appDir) or true:
            # remove from node then save nakefile.json to the appdir
            # remove:
            # init section
            # init_var section
            jnode.delete("init")
            jnode.delete("init_var")
            let f = open(joinPath(appDir, jsonNakefile), FileMode.fmWrite)
            f.write(jnode.pretty(2))
            f.close()
            echo &"app {appName} created."
        else:
          echo &"no init section template {jsonNakefile}."
    else:
      echo &"{fpath} not found."
  else:
    echo &"{appType} template not found."
  
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
    let appName = cmdParams[1]
    if not setDefaultApp(appName) and not isAppExists(appName):
      echo &"app {appName} doesn't exist."
    else:
      echo &"default app changed to {appName}."
  else:
    echo defaultApp()

task "debug", "build debug app, Ex: nake debug [appname].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len() > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var actionList = loadJsonNakefile(appName){"debug"}
    if not isNil(actionList):
      actionList = parseJson(
        ($actionList).replace("::", $DirSep)
        .replace("{current_app_dir}", currentAppDir(appName)))
      doActionList(actionList)

  else:
    echo "invalid arguments."

task "release", "build release app, Ex: nake release [appname].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len() > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var actionList = loadJsonNakefile(appName){"release"}
    if not isNil(actionList):
      actionList = parseJson(
        ($actionList).replace("::", $DirSep)
        .replace("{current_app_dir}", currentAppDir(appName)))
      doActionList(actionList)

  else:
    echo "invalid arguments."

task "run", "run app, ex: nake run [appname].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len() > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var actionList = loadJsonNakefile(appName){"run"}
    if not isNil(actionList):
      actionList = parseJson(
        ($actionList).replace("::", $DirSep)
        .replace("{current_app_dir}", currentAppDir(appName)))
      doActionList(actionList)

  else:
    echo "invalid arguments."

task "debug-run", "build debug and then run the app. Ex: nake debug-run [appname].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len() > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var jnode = loadJsonNakefile(appName)
    for actionList in [jnode{"debug"}, jnode{"run"}]:
      if not isNil(actionList):
        let actionToDo = parseJson(
          ($actionList).replace("::", $DirSep)
          .replace("{current_app_dir}", currentAppDir(appName)))
        doActionList(actionToDo)

  else:
    echo "invalid arguments."

task "release-run", "build release and then run the app. Ex: nake release-run [appname].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len() > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var jnode = loadJsonNakefile(appName)
    for actionList in [jnode{"release"}, jnode{"run"}]:
      if not isNil(actionList):
        let actionToDo = parseJson(
          ($actionList).replace("::", $DirSep)
          .replace("{current_app_dir}", currentAppDir(appName)))
        doActionList(actionToDo)

  else:
    echo "invalid arguments."

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
    for i in 1..high(cmdParams):
      let appDir = joinPath(appsDir, cmdParams[i])
      if existsDir(appDir):
        removeDir(appDir, true)
        if not existsDir(appDir):
          echo &"{appDir} deleted."
        else:
          echo &"fail to delete {appDir}."
      else:
        echo &"{appDir} not found."
    echo ""
    echo "available apps:"
    shell("nake list-apps")
  else:
    echo "invalid arguments."

task "install-deps", "install nimble app depedencies. Ex: nake install-deps [appname].":
  let defApp = defaultApp()
  if not existsDir(nimdepsDir):
    createDir(nimdepsDir)

  if cmdParams.len() > 1:
    let appName = cmdParams[1]
    installDeps(appName)

  elif isAppExists(defApp.appName) or not isUmbrellaMode():
    installDeps(defApp.appName)

  else:
    echo "invalid arguments."

task "help", "show available tasks. Ex: nake help.":
  shell("nake")
