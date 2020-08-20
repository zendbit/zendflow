import nake, nakelib, os, strutils, strformat,
  json, osproc, re, distros, times
import nwatchdog

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
let watchDog = NWatchDog[JsonNode]()

const
  jsonNakefile = "nakefile.json"
  nimdepsDir = ".nimdeps"

# init appsDir and templatesDir
# depend on the top level of the nakefile.json
if jsonNakefile.existsFile:
  let jnode = jsonNakefile.parseFile()
  appsDir = jnode{"appsDir"}.getStr().replace("::", $DirSep)
  templatesDir = jnode{"templatesDir"}.getStr().replace("::", $DirSep)

proc copyDir(src, dest: string, newer: bool = true) =
  #[
    copy dir and file if newer only
    default newer params is true
    if it newer false just user the os.copyDir
  ]#
  if not newer:
    os.copyDir(src, dest)
  else:
    if src.existsDir:
      if not dest.existsDir:
        dest.createDir
      for f in src.walkDirRec:
        let destPath = dest.joinPath(f.replace(src, ""))
        if f.existsDir:
          if not destPath.existsDir:
            destPath.createDir
        if f.existsFile:
          if destPath.existsFile:
            if f.getLastModificationTime() < destPath.getLastModificationTime():
              continue
          let destDir = destPath.splitPath.head
          if not destDir.existsFile:
            destDir.createDir
        f.copyFile(destPath)

proc copyFile(src, dest: string, newer: bool = true) =
  #[
    copy file if newer only
    default newer params is true
    if it newer false just user the os.copyDir
  ]#
  if src.existsFile and dest.existsFile and newer:
    if src.getLastModificationTime() < dest.getLastModificationTime():
      return

  os.copyFile(src, dest)

proc isInPlatform(platform: string): bool =
  #
  # define on platform specific
  # currently will check
  # onPlatform : {
  #   "windows": {},
  #   "macosx": {},
  #   "posix": {},
  #   "bsd": {}
  # }
  #

  case platform.toLower
  of ($Windows).toLower:
    result = detectOs(Windows)
  of ($Posix).toLower:
    result = detectOs(Posix)
  of ($MacOSX).toLower:
    result = detectOs(MacOSX)
  of ($BSD).toLower:
    result = detectOs(BSD)

proc loadJsonNakefile(appName: string = ""): JsonNode =
  #
  # load nakefile.json
  #
  result = %*{}
  try:
    if appsDir.joinPath(appName, jsonNakefile).existsFile:
      result = appsDir.joinPath(appName, jsonNakefile).parseFile()
    elif jsonNakefile.existsFile:
      result = jsonNakefile.parseFile()
  except Exception:
    discard

proc isUmbrellaMode(showMsg: bool = false): bool =
  #
  # check is in umbrella mode
  # the umbrella mode is in the top of zendflow dir
  # non umbrella mode is in the application dir
  #
  if not templatesDir.existsDir:
    if showMsg:
      echo ""
      echo "Not in umbrella mode."
      echo "Command new, delete, list-apps, default-app not allowed."
      echo ""
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

proc subtituteVar(varnode: JsonNode): JsonNode =
  # this function will subtitute variable
  # defined int the nakefile.json
  # ex:
  # {"foo": "hello", "bar": "{foo} world"}
  # into {"foo": "hello", "bar": "hello world"}
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

proc cleanDoubleColon(str: string): string =
  # this will remove leading or ending double colon
  # ::hello::world::
  # will transform to hello::world
  result = str.strip()
  if result == "::" or result == "":
    result = ""
  else:
    if result.startsWith("::"):
      result = result.subStr(2, high(result))

    if result.endsWith("::"):
      result = result.subStr(0, high(result) - 2)

proc moveDirContents(src: string, dest: string, includes: JsonNode, excludes: JsonNode = nil, mode = "copy", fileOnly = false) =
  #
  # for move dir contents of dir
  # with filtering options
  #
  echo &"{mode} {src}{$DirSep}{includes} -> {dest}{$DirSep}{includes}"
  for (kind, path) in src.walkDir:
    let filename = path.extractFilename
    let pathSrc = src.joinPath(filename)
    let pathDest = dest.joinPath(filename)
    if not excludes.isNil and %filename in excludes:
      continue
    if fileOnly and (kind == pcDir or kind == pcLinkToDir): continue
    if %filename in includes or %"*" in includes:
      if kind == pcFile or kind == pcLinkToFile:
        case mode
        of "copy":
          pathSrc.copyFile(pathDest)
        of "move":
          pathSrc.moveFile(pathDest)
      else:
        case mode
        of "copy":
          pathSrc.copyDir(pathDest)
        of "move":
          pathSrc.moveDir(pathDest)

proc removeDirContents(src: string, includes: JsonNode, excludes: JsonNode = nil, fileOnly = false) =
  #
  # for remove contents of dir
  # with filtering options
  #
  echo &"remove {src}{$DirSep}{includes}"
  for (kind, path) in src.walkDir:
    let filename = path.extractFilename
    let pathSrc = src.joinPath(filename)
    if not excludes.isNil and %filename in excludes:
      continue
    if fileOnly and (kind == pcDir or kind == pcLinkToDir): continue
    if %filename in includes or %"*" in includes:
      if kind == pcFile or kind == pcLinkToFile:
        pathSrc.removeFile
      else:
        pathSrc.removeDir

proc doActionList(actionList: JsonNode) =
  #
  # will process action list
  # process tasks section in the nakefile.json
  #
  if not actionList.isNil and actionList.kind == JsonNodeKind.JArray:
    for action in actionList:
      # check on platform action
      # then override the action command
      let onPlatform = action{"onPlatform"}
      var onPlatformAction: JsonNode
      if not onPlatform.isNil:
        for k, v in onPlatform:
          if k.isInPlatform:
            # override depend on the onplatform specific
            if not onPlatformAction.isNil:
              for k, v in onPlatformAction:
                action[k] = v
            break

      let actionType = action{"action"}.getStr()
      case actionType
      of "copyDir", "copyFile", "moveFile",
        "moveDir", "createHardlink", "createSymlink":
        let list = action{"list"}
        if not list.isNil:
          for l in list:
            let src = l{"src"}
            let dest = l{"dest"}
            let includes = l{"includes"}
            let excludes = l{"excludes"}
            if not src.isNil and not dest.isNil:
              let src = src.getStr().cleanDoubleColon
              let dest = dest.getStr().cleanDoubleColon
              let next = l{"next"}
              let err = l{"err"}
              let desc = l{"desc"}
              if not desc.isNil:
                echo desc.getStr()
              var errMsg = ""
              try:
                case actionType
                of "copyDir":
                  if includes.isNil:
                    echo &"copy {src} -> {dest}"
                    src.copyDir(dest)
                  else:
                    src.moveDirContents(dest, includes, excludes, "copy")
                of "copyFile":
                  if includes.isNil:
                    echo &"copy {src} -> {dest}"
                    src.copyFile(dest)
                  else:
                    src.moveDirContents(dest, includes, excludes, "copy", true)
                of "moveFile":
                  if includes.isNil:
                    echo &"move {src} -> {dest}"
                    src.moveFile(dest)
                  else:
                    src.moveDirContents(dest, includes, excludes, "move", true)
                of "moveDir":
                  if includes.isNil:
                    echo &"move {src} -> {dest}"
                    src.moveDir(dest)
                  else:
                    src.moveDirContents(dest, includes, excludes, "move")
                of "createSymlink":
                  echo &"symlink {src} -> {dest}"
                  src.createSymlink(dest)
                of "createHardlink":
                  echo &"hardlink {src} -> {dest}"
                  src.createHardlink(dest)
              except Exception as ex:
                errMsg = ex.msg

              if errMsg != "":
                echo errMsg
                if not err.isNil and err.kind == JsonNodeKind.JArray:
                  err.doActionList

              else:
                if not next.isNil and next.kind == JsonNodeKind.JArray:
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
        if errCode != 0:
          if not err.isNil and err.kind == JsonNodeKind.JArray:
            err.doActionList

        else:
          if not next.isNil and next.kind == JsonNodeKind.JArray:
            next.doActionList

      of "replaceStr":
        let desc = action{"desc"}
        if not desc.isNil:
          echo desc.getStr()

        let file = action{"file"}
        let list = action{"list"}
        let next = action{"next"}
        let err = action{"err"}
        echo &"replace str in file -> {file}"
        var errMsg = ""
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
          except Exception as ex:
            echo ex.msg
            errMsg = ex.msg
            if not err.isNil and err.kind == JsonNodeKind.JArray:
              err.doActionList
          
          if errMsg == "":
            if not next.isNil and next.kind == JsonNodeKind.JArray:
              next.doActionList

      of "removeFile", "removeDir", "createDir":
        let list = action{"list"}
        if not list.isNil and list.kind == JsonNodeKind.JArray:
          for l in list:
            if l.kind == JsonNodeKind.JObject:
              let name = l{"name"}
              let desc = l{"desc"}
              let next = l{"next"}
              let err = l{"err"}
              let includes = l{"includes"}
              let excludes = l{"excludes"}
              var errMsg = ""

              if not desc.isNil:
                echo desc.getStr()

              if not name.isNil:
                let name = name.getStr().cleanDoubleColon()
                try:
                  case actionType
                  of "removeFile":
                    if includes.isNil:
                      echo &"remove -> {name}"
                      name.removeFile()
                    else:
                      name.removeDirContents(includes, excludes, true)
                  of "removeDir":
                    if includes.isNil:
                      echo &"remove -> {name}"
                      name.removeDir()
                    else:
                      name.removeDirContents(includes, excludes)
                  of "createDir":
                    echo &"create -> {name}"
                    name.createDir()
                except Exception as ex:
                  errMsg = ex.msg

              if errMsg != "":
                echo errMsg
                if not err.isNil and err.kind == JsonNodeKind.JArray:
                  err.doActionList
              
              else:
                if not next.isNil and next.kind == JsonNodeKind.JArray:
                  next.doActionList

      of "watch":
        let list = action{"list"}
        if not list.isNil and list.kind == JsonNodeKind.JArray:
          for l in list:
            let dir = l{"dir"}
            let pattern = l{"pattern"}
            if not dir.isNil and not pattern.isNil:
              watchDog.add(
                dir.getStr,
                pattern.getStr,
                proc (file: string, event: NWatchEvent, param: JsonNode) =
                  let onModified = param{"onModified"}
                  let onCreated = param{"onCreated"}
                  let onDeleted = param{"onDeleted"}
                  case event
                  of Modified:
                    if not onModified.isNil:
                      onModified.doActionList
                  of Created:
                    if not onCreated.isNil:
                      onCreated.doActionList
                  of Deleted:
                    if not onDeleted.isNil:
                      onDeleted.doActionList,
                l.copy)
          echo "watch started."
          waitFor watchDog.watch
      else:
        echo &"{actionType} action not implemented."
  else:
    echo "not valid action list, action list should be in json array."

proc defaultApp(): tuple[appName: string, appType: string] =
  #
  # get default app
  # return tupple with appName and appType
  #
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
  #
  # set default app
  #
  let jsonNake = loadJsonNakefile()
  if not jsonNake{"jsonNakefile"}.isNil:
    jsonNake["jsonNakefile"] = %appsDir.joinPath(appName, jsonNakefile)
    let f = jsonNakefile.open(FileMode.fmWrite)
    f.write(jsonNake.pretty(2))
    f.close()
    result = true

proc currentAppDir(appName: string): string =
  #
  # get current app dir with given appname
  #
  result = "."
  if isInPlatform($Windows): result = ""
  if appsDir != "":
    result = appsDir.joinPath(appName)

proc isAppExists(appName: string): bool =
  #
  # check if application name folder exists
  #
  result = appsDir.joinPath(appName).existsDir and
    appsDir.joinPath(appName, jsonNakefile).existsFile

  # check if the jsonNakefile contains appInfo -> appName
  # this mean directly run from the app dir
  if not result:
    let jnake = loadJsonNakefile()
    if not jnake{"appInfo"}.isNil:
      result = not jnake{"appInfo"}{"appName"}.isNil

proc installDeps(appName: string) =
  #
  # install depedencies in the nimble section
  # nakefile.json
  #
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
          if errMsg != "" and errMsg.toLower().contains("'"):
            var depDir: array[1, string]
            if errMsg.match(re"[\w\W]+\'([\w\W]+)\'[\w\W]+$", depDir):
              if depDir[0].existsDir:
                @["cd", depDir[0], "&&", "git", "pull"].join(" ").shell

      else:
        echo output

proc existsTemplates(templateName: string): bool =
  #
  # check if template exists
  # available template is in the .template dir
  #
  for kind, path in templatesDir.walkDir:
    if kind == PathComponent.pcDir and
      path.endsWith(DirSep & templateName):
      return true

proc showTemplateList() =
  #
  # show available template list
  #
  if templatesDir.existsDir:
    echo ""
    for kind, path in templatesDir.walkDir:
      if kind == PathComponent.pcDir:
        let f = path.joinPath(jsonNakefile)
        if f.existsFile:
          let appInfo = f.parseFile(){"appInfo"}
          if not appInfo.isNil and appInfo.hasKey("appType") and
            appInfo.hasKey("appDesc"):
            echo appInfo{"appType"}.getStr & " -> " & appInfo{"appDesc"}.getStr
    echo ""

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
      #var fcontent = f.readAll().replace("{appName}", appName)
      var fcontent = f.readAll()
      f.close()

      var jnode = fcontent.parseJson()
      if not isNil(jnode):
        jnode["appInfo"]["appName"] = %appName
        jnode["appInfo"]["appType"] = %appType
        fcontent = $jnode

        var varnode = jnode{"initVar"}
        var initNode = jnode{"init"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            #fcontent = fcontent.replace("{" & k & "}", v.getStr())
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        varnode = jnode{"appInfo"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            #fcontent = fcontent.replace("{" & k & "}", v.getStr())
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        # replace templates and apps dir definition
        # this defined in the base nakefile.json
        #fcontent = fcontent.replace("{templatesDir}", templatesDir)
        #fcontent = fcontent.replace("{appsDir}", appsDir)
        initNode = ($initNode).replace("{templatesDir}", templatesDir).parseJson
        initNode = ($initNode).replace("{appsDir}", appsDir).parseJson
        jnode["init"] = initNode.copy

        #jnode = fcontent.parseJson()
        initnode = jnode{"init"}
        if not initnode.isNil and initnode.kind == JsonNodeKind.JArray:
          ($initNode).replace("::", $DirSep)
            .replace("{appName}", appName).parseJson().doActionList
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
            echo &"app {appDir} created."
        else:
          echo &"no init section template {jsonNakefile}."
    else:
      echo &"{fpath} not found."
  else:
    echo &"{appType} template not found."

task "templates", "show template available app template.":
  if not true.isUmbrellaMode():
    return
  showTemplateList()

task "new", "create new app. Ex: nake new console.":
  if not true.isUmbrellaMode():
    return

  if cmdParams.len > 2:
    let appName = cmdParams[2]
    let appType = cmdParams[1]
    var appNameMatch: array[1, string]
    if appName.match(re"([a-z\d_]+)*$", appNameMatch):
      appName.newApp(appType)
    else:
      echo ""
      echo "application name is not valid, only a-z0-9_"
      echo "example valid name:"
      echo "-> my_blog"
      echo "-> my_blog32"
      echo "-> my32"
      echo "-> my_blog_32"
      echo "-> 12345"
      echo "-> myblog"
      echo ""

  else:
    echo "invalid new command arguments."

task "default-app", "get/set default app. Ex: nake default-app [appName].":
  if not isUmbrellaMode(true):
    return

  if cmdParams.len > 1:
    let appName = cmdParams[1]
    if not appName.setDefaultApp() and not appName.isAppExists():
      echo ""
      echo &"app {appName} doesn't exist."
      echo ""
    else:
      echo ""
      echo &"default app changed to {appName}."
      echo ""
  else:
    echo defaultApp()

task "list-apps", "show available app. Ex: nake list-app":
  if not true.isUmbrellaMode():
    return

  if appsDir.existsDir:
    echo ""
    for dir in joinPath(appsDir, "*").walkDirs:
      if dir.joinPath(jsonNakefile).existsFile:
        echo "-> " & dir.extractFilename()
    echo ""

task "delete-app", "delete app. Ex: nake delete-app appName.":
  if not true.isUmbrellaMode():
    return

  if cmdParams.len > 1:
    for i in 1..cmdParams.high():
      let appDir = appsDir.joinPath(cmdParams[i])
      if appDir.existsDir:
        appDir.removeDir
        if not appDir.existsDir:
          echo ""
          echo &"{appDir} deleted."
          echo ""
        else:
          echo ""
          echo &"fail to delete {appDir}."
          echo ""
      else:
        echo ""
        echo &"{appDir} not found."
        echo ""
    echo ""
    echo "available apps:"
    shell("nake list-apps")
  else:
    echo ""
    echo "invalid arguments."
    echo ""

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
    echo ""
    echo "invalid arguments."
    echo ""

task "help", "show available tasks. Ex: nake help.":
  "nake".shell()

#
# make nake run with nakefile.json task description
# this make more portable
#
let defApp = defaultApp()
var appName = defApp.appName

if cmdParams.len > 1:
  appName = cmdParams[1]

proc addNakeTask(name: string, desc: string, taskList: JsonNode) =
  if not taskList.isNil and taskList.kind == JsonNodeKind.JArray:
    task name, desc:
      let actionToDo = ($taskList).replace("::", $DirSep)
        .replace("{currentAppDir}", appName.currentAppDir)
        .replace("{appName}", appName).parseJson
      actionToDo.doActionList
  else:
    echo &"invalid task list {name} , should be in JArray."

if appName.isAppExists():
  var jnode = appName.loadJsonNakefile()
  if not jnode.hasKey("init") and not jnode.hasKey("initVar"):
    for k, v in jnode:
      if k in ["appInfo", "nimble"]:
        continue
      var desc = v{"desc"}.getStr
      if desc == "": desc = k
      let actionList = v{"tasks"}
      k.addNakeTask(desc, actionList)
