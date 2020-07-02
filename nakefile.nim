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
  nimdepsDir = ".nimdeps"

# init appsDir and templatesDir
# depend on the top level of the nakefile.json
if jsonNakefile.existsFile:
  let jnode = jsonNakefile.parseFile()
  appsDir = jnode{"appsDir"}.getStr().replace("::", $DirSep)
  templatesDir = jnode{"templatesDir"}.getStr().replace("::", $DirSep)

proc loadJsonNakefile(appName: string = ""): JsonNode =
  result = %*{}
  try:
    if appsDir.joinPath(appName, jsonNakefile).existsFile:
      result = appsDir.joinPath(appName, jsonNakefile).parseFile()
    elif jsonNakefile.existsFile:
      result = jsonNakefile.parseFile()
  except Exception:
    discard

proc isUmbrellaMode(showMsg: bool = false): bool =
  if not templatesDir.existsDir:
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
    discard appsDir.existsOrCreateDir()
    if not jsonNakefile.existsFile:
      let f = jsonNakefile.open(FileMode.fmWrite)
      f.write((%*{
        "jsonNakefile": "",
        "templatesDir": ".templates",
        "appsDir": "apps"}).pretty())
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
  if not actionList.isNil and actionList.kind == JsonNodeKind.JArray:
    for action in actionList:
      let actionType = action{"action"}.getStr()
      case actionType
      of "copyDir", "copyFile", "moveFile", "moveDir":
        let list = action{"list"}
        if not list.isNil:
          for l in list:
            let src = l{"src"}
            let dest = l{"dest"}
            if not src.isNil and not dest.isNil:
              let src = src.getStr().cleanDoubleColon()
              let dest = dest.getStr().cleanDoubleColon()
              let next = l{"next"}
              let err = l{"err"}
              let desc = l{"desc"}
              if not desc.isNil:
                echo desc.getStr()
              var errMsg = ""
              try:
                case actionType
                of "copyDir":
                  echo &"copy dir {src} -> {dest}"
                  src.copyDir(dest)
                of "copyFile":
                  echo &"copy file {src} -> {dest}"
                  src.copyFile(dest)
                of "moveFile":
                  echo &"move file {src} -> {dest}"
                  src.moveFile(dest)
                of "moveDir":
                  echo &"move dir {src} -> {dest}"
                  src.moveDir(dest)
              except Exception as ex:
                errMsg = ex.msg

              if errMsg != "" and not err.isNil and err.kind == JsonNodeKind.JArray:
                echo errMsg
                err.doActionList
              elif not next.isNil and next.kind == JsonNodeKind.JArray:
                next.doActionList

      of "cmd":
        let desc = action{"desc"}
        if not desc.isNil:
          echo desc.getStr()

        var exe = ""
        if not action{"exe"}.isNil:
          exe = action{"exe"}.getStr().cleanDoubleColon()

        var props = action{"props"}
        var options = ""
        if not action{"options"}.isNil:
          options = action{"options"}.getStr().cleanDoubleColon()

        if not props.isNil:
          props = props.subtituteVar()
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

        let next = action{"next"}
        let err = action{"err"}
        echo &"""exec cmd -> {cmd.join(" ")}"""
        let errCode = cmd.join(" ").execCmd()
        if errCode == 0:
          if not next.isNil and next.kind == JsonNodeKind.JArray:
            next.doActionList
        else:
          if not err.isNil and err.kind == JsonNodeKind.JArray:
            err.doActionList

      of "replaceStr":
        let desc = action{"desc"}
        if not desc.isNil:
          echo desc.getStr()

        let file = action{"file"}
        let list = action{"list"}
        let next = action{"next"}
        let err = action{"err"}
        echo &"replace str in file -> {file}"
        if not file.isNil and not list.isNil and file.getStr().existsFile:
          try:
            var f = file.getStr().open(FileMode.fmRead)
            var fstr = f.readAll()
            f.close()
            if not list.isNil and list.kind == JsonNodeKind.JArray:
              for l in list:
                let oldstr = l{"old"}
                let newstr = l{"new"}
                if not oldstr.isNil and not newstr.isNil:
                  echo &" {oldstr} -> {newstr}"
                  fstr = fstr.replace(
                    oldstr.getStr().cleanDoubleColon(),
                    newstr.getStr().cleanDoubleColon())
                  
              f = file.getStr().open(FileMode.fmWrite)
              f.write(fstr)
              f.close()
              if not next.isNil and next.kind == JsonNodeKind.JArray:
                next.doActionList
          except Exception as ex:
            echo ex.msg
            if not err.isNil and err.kind == JsonNodeKind.JArray:
              err.doActionList

      of "removeFile", "removeDir", "createDir":
        let list = action{"list"}
        if not list.isNil and list.kind == JsonNodeKind.JArray:
          for l in list:
            if l.kind == JsonNodeKind.JObject:
              let name = l{"name"}
              let desc = l{"desc"}
              let next = l{"next"}
              let err = l{"err"}
              var errMsg = ""

              if not desc.isNil:
                echo desc.getStr()

              if not name.isNil:
                let name = name.getStr().cleanDoubleColon()
                try:
                  case actionType
                  of "removeFile":
                    echo &"remove file -> {name}"
                    name.removeFile()
                  of "removeDir":
                    echo &"remove dir -> {name}"
                    name.removeDir()
                  of "createDir":
                    echo &"create dir -> {name}"
                    name.createDir()
                except Exception as ex:
                  errMsg = ex.msg

              if errMsg != "" and not err.isNil and err.kind == JsonNodeKind.JArray:
                echo errMsg
                err.doActionList
              elif not next.isNil and next.kind == JsonNodeKind.JArray:
                next.doActionList

      else:
        echo "{actionType} action not implemented."

  else:
    echo "not valid action list, action list should be in json array."

proc defaultApp(): tuple[appName: string, appType: string] =
  var appName = ""
  var appType = ""

  let jsonNake = loadJsonNakefile()
  if not isNil(jsonNake{"jsonNakefile"}):
    let forwardJsonNakefile = jsonNake{"jsonNakefile"}.getStr()
    if forwardJsonNakefile != "" and forwardJsonNakefile.existsFile:
      let jsonNake = forwardJsonNakefile.parseFile()
      appName = jsonNake{"appInfo"}{"appName"}.getStr()
      appType = jsonNake{"appInfo"}{"appType"}.getStr()
  
  else:
    appName = jsonNake{"appInfo"}{"appName"}.getStr()
    appType = jsonNake{"appInfo"}{"appType"}.getStr()

  return (appName, appType)

proc setDefaultApp(appName: string): bool =
  let jsonNake = loadJsonNakefile()
  if not jsonNake{"jsonNakefile"}.isNil:
    jsonNake["jsonNakefile"] = %appsDir.joinPath(appName, jsonNakefile)
    let f = jsonNakefile.open(FileMode.fmWrite)
    f.write(jsonNake.pretty(2))
    f.close()
    result = true

proc currentAppDir(appName: string): string =
  result = "."
  if appsDir != "":
    result = appsDir.joinPath(appName)

proc isAppExists(appName: string): bool =
  result = appsDir.joinPath(appName).existsDir and
    appsDir.joinPath(appName, jsonNakefile).existsFile

  # check if the jsonNakefile contains appInfo -> appName
  # this mean directly run from the app dir
  if not result:
    let jnake = loadJsonNakefile()
    if not jnake{"appInfo"}.isNil:
      result = not jnake{"appInfo"}{"appName"}.isNil


proc installDeps(appName: string) =
  let nimble = appName.loadJsonNakefile(){"nimble"}
  "nimble update".shell
  for pkg in nimble:
    let pkgName = pkg.getStr().replace("install ", "").replace("develop ", "")
    echo "trying get latest " & pkgName
    let pkgCmd = pkg.getStr().strip
    if pkgCmd.startsWith("install"):
      @["nimble", "-y", pkgCmd].join(" ").shell
    
    elif pkgCmd.startsWith("develop"):
      let (output, errorCode) = @["cd", nimdepsDir, "&&", "nimble", "-y", pkgCmd].join(" ").execCmdEx
      if errorCode != 0:
        for err in output.split("\n"):
          let errMsg = err.strip
          if errMsg != "" and errMsg.toLower().contains("error"):
            var depDir: array[1, string]
            if errMsg.match(re"[\w\W]+\'([\w\W]+)\'[\w\W]+$", depDir):
              if depDir[0].existsDir:
                @["cd", depDir[0], "&&", "git", "pull"].join(" ").shell

      else:
        echo output

proc existsTemplates(templateName: string): bool =
  for kind, path in templatesDir.walkDir:
    if kind == PathComponent.pcDir and
      path.endsWith(DirSep & templateName):
      return true

# this will read from templates nakefile.json
# .templates/appType/nakefile.json
# and will process init section
proc newApp(appName: string, appType: string) =
  let appDir = appsDir.joinPath(appName)

  if appName.isAppExists():
    echo &"App {appName} already exist."
    return

  if appType.existsTemplates():
    # load json from templates
    let fpath = templatesDir.joinPath(appType, jsonNakefile)
    if existsFile(fpath):
      let f = fpath.open(FileMode.fmRead)
      var fcontent = f.readAll().replace("{appName}", appName)
      f.close()

      var jnode = fcontent.parseJson()
      if not isNil(jnode):
        jnode["appInfo"]["appName"] = %appName
        jnode["appInfo"]["appType"] = %appType
        fcontent = $jnode

        var varnode = jnode{"initVar"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            fcontent = fcontent.replace("{" & k & "}", v.getStr())

        varnode = jnode{"appInfo"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            fcontent = fcontent.replace("{" & k & "}", v.getStr())

        # replace templates and apps dir definition
        # this defined in the base nakefile.json
        fcontent = fcontent.replace("{templatesDir}", templatesDir)
        fcontent = fcontent.replace("{appsDir}", appsDir)

        jnode = fcontent.parseJson()
        let initnode = jnode{"init"}
        if not initnode.isNil and initnode.kind == JsonNodeKind.JArray:
          ($initNode).replace("::", $DirSep).parseJson().doActionList
          
          if appDir.existsDir:
            # remove from node then save nakefile.json to the appdir
            # remove:
            # init section
            # initVar section
            jnode.delete("init")
            jnode.delete("initVar")
            let f = appDir.joinPath(jsonNakefile).open(FileMode.fmWrite)
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
  if not true.isUmbrellaMode():
    return

  if cmdParams.len > 2:
    let appName = cmdParams[2]
    let appType = cmdParams[1]
    appName.newApp(appType)

  else:
    echo "invalid new command arguments."

task "default-app", "get/set default app. Ex: nake default-app [appName].":
  if not isUmbrellaMode(true):
    return

  if cmdParams.len > 1:
    let appName = cmdParams[1]
    if not appName.setDefaultApp() and not appName.isAppExists():
      echo &"app {appName} doesn't exist."
    else:
      echo &"default app changed to {appName}."
  else:
    echo defaultApp()

task "debug", "build debug app, Ex: nake debug [appName].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len > 1:
    appName = cmdParams[1]

  if appName.isAppExists():
    var actionList = appName.loadJsonNakefile(){"debug"}
    if not isNil(actionList):
      actionList = ($actionList).replace("::", $DirSep)
        .replace("{currentAppDir}", appName.currentAppDir()).parseJson()
      actionList.doActionList

  else:
    echo "invalid arguments."

task "release", "build release app, Ex: nake release [appName].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len > 1:
    appName = cmdParams[1]

  if appName.isAppExists():
    var actionList = appName.loadJsonNakefile(){"release"}
    if not actionList.isNil:
      actionList = ($actionList).replace("::", $DirSep)
        .replace("{currentAppDir}", appName.currentAppDir()).parseJson()
      actionList.doActionList

  else:
    echo "invalid arguments."

task "run", "run app, ex: nake run [appName].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len > 1:
    appName = cmdParams[1]

  if isAppExists(appName):
    var actionList = appName.loadJsonNakefile(){"run"}
    if not actionList.isNil:
      actionList = ($actionList).replace("::", $DirSep)
        .replace("{currentAppDir}", appName.currentAppDir()).parseJson()
      actionList.doActionList

  else:
    echo "invalid arguments."

task "debug-run", "build debug and then run the app. Ex: nake debug-run [appName].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len > 1:
    appName = cmdParams[1]

  if appName.isAppExists():
    var jnode = appName.loadJsonNakefile()
    for actionList in [jnode{"debug"}, jnode{"run"}]:
      if not actionList.isNil:
        let actionToDo = ($actionList).replace("::", $DirSep)
          .replace("{currentAppDir}", appName.currentAppDir()).parseJson()
        actionToDo.doActionList

  else:
    echo "invalid arguments."

task "release-run", "build release and then run the app. Ex: nake release-run [appName].":
  let defApp = defaultApp()
  var appName = defApp.appName

  if cmdParams.len > 1:
    appName = cmdParams[1]

  if appName.isAppExists():
    var jnode = appName.loadJsonNakefile()
    for actionList in [jnode{"release"}, jnode{"run"}]:
      if not actionList.isNil:
        let actionToDo = ($actionList).replace("::", $DirSep)
          .replace("{currentAppDir}", appName.currentAppDir()).parseJson()
        actionToDo.doActionList

  else:
    echo "invalid arguments."

task "list-apps", "show available app. Ex: nake list-app":
  if not true.isUmbrellaMode():
    return

  if appsDir.existsDir:
    for dir in joinPath(appsDir, "*").walkDirs:
      if dir.joinPath(jsonNakefile).existsFile:
        echo "-> " & dir.extractFilename()

task "delete-app", "delete app. Ex: nake delete-app appName.":
  if not true.isUmbrellaMode():
    return

  if cmdParams.len > 1:
    for i in 1..cmdParams.high():
      let appDir = appsDir.joinPath(cmdParams[i])
      if appDir.existsDir:
        appDir.removeDir
        if not appDir.existsDir:
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

task "install-deps", "install nimble app depedencies. Ex: nake install-deps [appName].":
  let defApp = defaultApp()
  if not nimdepsDir.existsDir:
    nimdepsDir.createDir()

  if cmdParams.len > 1:
    let appName = cmdParams[1]
    appName.installDeps()

  elif defApp.appName.isAppExists() or not isUmbrellaMode():
    defApp.appName.installDeps()

  else:
    echo "invalid arguments."

task "help", "show available tasks. Ex: nake help.":
  "nake".shell()
