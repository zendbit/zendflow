##
##  nakefile.nim
##  the nake build system
##  will parse the nakefile.json into nake task
##
##  @author: Amru Rosyada
##  @email: amru.rosyada@gmail.com
##  @license: BSD
##
import
  nake,
  nakelib,
  os,
  strutils,
  strformat,
  json,
  osproc,
  re,
  distros,
  times,
  std/sha1

import NWatchdog

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
let watchDog = NWatchDog[JsonNode](interval: 100)

const
  jsonNakefile = "nakefile.json"

# init appsDir and templatesDir
# depend on the top level of the nakefile.json
if jsonNakefile.fileExists:
  let jnode = jsonNakefile.parseFile()
  appsDir = jnode{"appsDir"}
    .getStr()
    .replace("::", $DirSep)
  templatesDir = jnode{"templatesDir"}
    .getStr()
    .replace("::", $DirSep)

type
  FileOperationMode = enum
    COPY_MODE
    MOVE_MODE

proc copyFileToDir(src: string,
  dest: string,
  filter: string = "",
  recursive: bool = true,
  verbose: bool = false,
  withStructure: bool = true,
  structureOffset: string = "",
  mode: FileOperationMode = COPY_MODE) =

  ##
  ##  copyFileToDir(
  ##    src,  // source folder
  ##    dest, // destination folder
  ##    filter, // filter in regex string (optional)
  ##    recursive, // recursive copy (optional), default true
  ##    verbose, // default true
  ##    withStructure, // default true if false will not create same structure just flat file structure in the destination folder
  ##    mode) // copy mode, default COPY_MODE
  ##

  ## if src is file
  if src.fileExists:
    if filter != "" and src.findAll(re filter).len == 0:
      return
    
    let fileInfo = src.splitPath
    var destDir = dest

    if not recursive and withStructure:
      destDir = dest.joinPath(fileInfo.head)
      if structureOffset != "":
        destDir = dest.joinPath(fileInfo.head.replace(structureOffset, ""))
      if not destDir.dirExists:
        destDir.createDir


    if dest.dirExists:
      if recursive:
        src.copyFileToDir(
          destDir,
          filter,
          recursive,
          verbose,
          withStructure,
          structureOffset,
          mode)

      else:
        case mode:
          of COPY_MODE:
            src.copyFile(destDir.joinPath(fileInfo.tail))
          of MOVE_MODE:
            src.moveFile(destDir.joinPath(fileInfo.tail))

    else:
      case mode:
        of COPY_MODE:
          src.copyFile(destDir)
        of MOVE_MODE:
          src.moveFile(destDir)

  if not src.dirExists: return
  for (kind, path) in src.walkDir:

    var destDir = dest

    case kind
    of pcFile, pcLinkToFile:
      let fileInfo = path.splitPath

      if withStructure:
        destDir = fileInfo.head.replace(src, dest)

      let destFile = destDir.joinPath(fileInfo.tail)
      if filter != "" and
        fileInfo.tail.findAll(re filter).len == 0:
        continue

      if (path.fileExists and destFile.fileExists) and
        (path.sameFile(destFile) or path.sameFileContent(destFile)):
        continue

      if not destDir.dirExists:
        destDir.createDir

      if verbose:
        echo path & " -> " & destFile

      case mode
      of COPY_MODE:
        path.copyFile(destFile)

      of MOVE_MODE:
        path.moveFile(destFile)

    of pcDir, pcLinkToDir:
      if recursive:
        if withStructure:
          destDir = path.replace(src, dest)

        path.copyFileToDir(
          destDir,
          filter,
          recursive,
          verbose,
          withStructure,
          structureOffset,
          mode)

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
    if appsDir.joinPath(appName, jsonNakefile).fileExists:
      result = appsDir.joinPath(appName, jsonNakefile).parseFile()
    elif jsonNakefile.fileExists:
      result = jsonNakefile.parseFile()
  except Exception:
    discard

proc isUmbrellaMode(showMsg: bool = false): bool =
  #
  # check is in umbrella mode
  # the umbrella mode is in the top of zendflow dir
  # non umbrella mode is in the application dir
  #
  if not templatesDir.dirExists:
    if showMsg:
      echo ""
      echo "Not in umbrella mode."
      echo "Command new, delete, list-apps, default-app not allowed."
      echo ""
    result = false
  else:
    # check if apps folder exist, if not create the dir
    discard appsDir.existsOrCreateDir()
    if not jsonNakefile.fileExists:
      let f = jsonNakefile.open(FileMode.fmWrite)
      f.write((%*{
        "jsonNakefile": "",
        "templatesDir": ".templates",
        "appsDir": "apps"}).pretty())
      f.close()
    result = true

proc escapePattern(patternStr: string): string =
  result = patternStr
  # check if pattern have to escaped the string
  for rgx in re.findAll(result, re"(``.*?``)"):
    result = result.replace(rgx, rgx.subStr(2, rgx.len - 3).escapeRe)

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

proc moveDirContents(src: string,
  dest: string,
  mode: FileOperationMode = COPY_MODE,
  fileOnly: bool = false,
  filter: string = "",
  withStructure: bool = true,
  structureOffset: string = "",
  recursive: bool = true) =

  ##
  ##  for move dir contents of dir
  ##  with filtering options
  ##
  echo &"{mode} {src} -> {dest}"
  if filter != "":
    echo &"  -> with filter {filter}"

  if fileOnly:
    src.copyFileToDir(
      dest,
      filter = filter,
      recursive = recursive,
      withStructure = withStructure,
      structureOffset = structureOffset,
      mode = mode
      )

  else:
    case mode
    of COPY_MODE:
      src.copyDir(dest)
    of MOVE_MODE:
      src.moveDir(dest)

proc removeDirContents(
  src: string,
  fileOnly: bool = false,
  filter: string = ""
  ) =

  #
  # for remove contents of dir
  # with filtering options
  #
  echo &"remove {src}"
  if filter != "":
    echo &"  -> with filter {filter}"
  
  for (kind, path) in src.walkDir:
    let filename = path.extractFilename
    let pathSrc = src.joinPath(filename)
    if fileOnly and (kind == pcDir or kind == pcLinkToDir):
      continue
    
    # if filter not empty string
    # and pathSrc not match with filter continue
    if filter != "":
      if pathSrc.findAll(re filter).len == 0:
        continue
    
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
            let filter = l{"filter"}.getStr.escapePattern

            var withStructure = true
            if not l{"withStructure"}.isNil:
              withStructure = l{"withStructure"}.getBool

            var structureOffset = ""
            if not l{"structureOffset"}.isNil:
              structureOffset = l{"structureOffset"}.getStr

            var recursive = true
            if not l{"recursive"}.isNil:
              recursive = l{"recursive"}.getBool

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
                  if filter == "":
                    echo &"copy {src} -> {dest}"
                    src.copyDir(dest)
                  else:
                    src.moveDirContents(dest,
                      COPY_MODE,
                      false,
                      filter,
                      withStructure,
                      structureOffset,
                      recursive)
                of "copyFile":
                  if filter == "":
                    echo &"copy {src} -> {dest}"
                    src.copyFile(dest)
                  else:
                    src.moveDirContents(dest,
                      COPY_MODE,
                      true,
                      filter,
                      withStructure,
                      structureOffset,
                      recursive)
                of "moveFile":
                  if filter == "":
                    echo &"move {src} -> {dest}"
                    src.moveFile(dest)
                  else:
                    src.moveDirContents(dest,
                      MOVE_MODE,
                      true,
                      filter,
                      withStructure,
                      structureOffset,
                      recursive)
                of "moveDir":
                  if filter == "":
                    echo &"move {src} -> {dest}"
                    src.moveDir(dest)
                  else:
                    src.moveDirContents(dest,
                      MOVE_MODE,
                      false,
                      filter,
                      withStructure,
                      structureOffset,
                      recursive)
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
          exe = action{"exe"}
            .getStr()
            .cleanDoubleColon()

        var props = action{"props"}
        var options = ""
        if not action{"options"}.isNil:
          options = action{"options"}
            .getStr()
            .cleanDoubleColon()

        if not props.isNil:
          props = props.subtituteVar()
          for k, v in props:
            let vstr = v.getStr()
              .cleanDoubleColon()
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

        let files = action{"files"}
        let list = action{"list"}
        let next = action{"next"}
        let err = action{"err"}
        var errMsg = ""
        
        echo &"replace str in files -> {files}"

        if not files.isNil and not list.isNil:
          for file in files:
            if file.getStr().fileExists:
              try:
                var f = file.getStr()
                  .open(FileMode.fmRead)
                var fstr = f.readAll()
                f.close()

                if not list.isNil and
                  list.kind == JsonNodeKind.JArray:

                  for l in list:
                    let oldstr = l{"old"}
                    let newstr = l{"new"}
                    if not oldstr.isNil and not newstr.isNil:
                      echo &" {oldstr} -> {newstr}"


                      # find rgx on pattern then escape it
                      let regReplaceStr = oldStr.getStr.cleanDoubleColon.escapePattern

                      fstr = re.replace(
                        fstr,
                        re regReplaceStr,
                        newstr.getStr().cleanDoubleColon()
                        )
                      
                  f = file.getStr()
                    .open(FileMode.fmWrite)
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
              let filter = l{"filter"}.getStr.escapePattern
              var errMsg = ""

              if not desc.isNil:
                echo desc.getStr()

              if not name.isNil:
                let name = name.getStr()
                  .cleanDoubleColon()
                try:
                  case actionType
                  of "removeFile":
                    if filter == "":
                      echo &"remove -> {name}"
                      name.removeFile()
                    else:
                      name.removeDirContents(true, filter)
                  of "removeDir":
                    if filter == "":
                      echo &"remove -> {name}"
                      name.removeDir()
                    else:
                      name.removeDirContents(false, filter)
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
            let dirs = l{"dirs"}
            let pattern = l{"pattern"}

            if not dirs.isNil and dirs.kind == JArray and not pattern.isNil:
              for dir in dirs:
                watchDog.add(
                  dir.getStr,
                  pattern.getStr.escapePattern,
                  proc (file: string, event: NWatchEvent, param: JsonNode) {.gcsafe async.} =
                    let pattern = param{"pattern"}.getStr.escapePattern
                    let onModified = param{"onModified"}
                    let onCreated = param{"onCreated"}
                    let onDeleted = param{"onDeleted"}
                    let eventsList =  param{"events"}
                    let (dir, name, ext) = file.splitFile

                    ##  export multiple events combination
                    var events: seq[JsonNode]
                    if not eventsList.isNil:
                      events = param{"events"}.to(seq[JsonNode])
                      for evt in events:
                        let action = evt{"action"}.to(seq[string])
                        if &"on{event}" in action:
                          ($(evt{"list"}))
                            .replace("{eventFilePath}", file)
                            .replace("{eventFileDir}", dir)
                            .replace("{eventFileName}", name & ext)
                            .parseJson
                            .doActionList

                    ## for single event
                    case event
                    of Modified:
                      if not onModified.isNil:
                        if file.findAll(re pattern).len != 0:
                          ($onModified)
                            .replace("{modifiedFilePath}", file)
                            .replace("{modifiedFileDir}", dir)
                            .replace("{modifiedFileName}", name & ext)
                            .parseJson
                            .doActionList
                    of Created:
                      if not onCreated.isNil:
                        if file.findAll(re pattern).len != 0:
                          ($onCreated)
                            .replace("{createdFilePath}", file)
                            .replace("{createdFileDir}", dir)
                            .replace("{createdFileName}", name & ext)
                            .parseJson
                            .doActionList
                    of Deleted:
                      if not onDeleted.isNil:
                        if file.findAll(re pattern).len != 0:
                          ($onDeleted)
                            .replace("{deletedFilePath}", file)
                            .replace("{deletedFileDir}", dir)
                            .replace("{deletedFileName}", name & ext)
                            .parseJson
                            .doActionList,
                  l.copy)
          echo "watch started."
          waitFor watchDog.watch
      else:
        echo &"{actionType} action not implemented."
  else:
    echo "not valid action list, action list should be in json array."

proc appInfo(name: string = ""): tuple[
  appName: string,
  appId: string,
  appType: string,
  appVersion: string] =

  #
  # get app info
  # return tupple with appName and appType
  #
  var appName = name
  var appType = ""
  var appId = ""
  var appVersion = ""

  let jsonNake = loadJsonNakefile(appName)
  if not isNil(jsonNake{"jsonNakefile"}):
    let forwardJsonNakefile = jsonNake{"jsonNakefile"}.getStr()
    if forwardJsonNakefile != "" and forwardJsonNakefile.fileExists:
      let jsonNake = forwardJsonNakefile.parseFile()
      appName = jsonNake{"appInfo"}{"appName"}.getStr()
      appType = jsonNake{"appInfo"}{"appType"}.getStr()
      appId = jsonNake{"appInfo"}{"appId"}.getStr()
      appVersion = jsonNake{"appInfo"}{"appVersion"}.getStr()
  
  else:
    appName = jsonNake{"appInfo"}{"appName"}.getStr()
    appType = jsonNake{"appInfo"}{"appType"}.getStr()
    appId = jsonNake{"appInfo"}{"appId"}.getStr()
    appVersion = jsonNake{"appInfo"}{"appVersion"}.getStr()

  return (appName, appId, appType, appVersion)

proc defaultApp(): tuple[
  appName: string,
  appId: string,
  appType: string,
  appVersion: string] =

  #
  # get default app
  # return tupple with appName and appType
  #
  
  result = appInfo()

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

proc workingDir(appName: string): string =
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
  result = appsDir.joinPath(appName).dirExists and
    appsDir.joinPath(appName, jsonNakefile).fileExists

  # check if the jsonNakefile contains appInfo -> appName
  # this mean directly run from the app dir
  if not result:
    let jnake = loadJsonNakefile()
    if not jnake{"appInfo"}.isNil:
      result = not jnake{"appInfo"}{"appName"}.isNil

proc installGlobalDeps(appName: string) =
  #
  # install depedencies in the nimble section
  # nakefile.json
  #
  let nimble = appName.loadJsonNakefile(){"nimble"}{"global"}
  
  if nimble.isNil:
    echo "no global nimble deps."
    return
  
  "nimble update".shell
  let workDir = getCurrentDir()
  let packagesDir = workDir.joinPath("packages")
  let nimbleDir = packagesDir.joinPath("nimble")
  let devpkgsDir = nimbleDir.joinPath("devpkgs")
  
  if not packagesDir.dirExists:
    packagesDir.createDir
  
  if not nimbleDir.dirExists:
    nimbleDir.createDir
  
  if not devpkgsDir.dirExists:
    devpkgsDir.createDir

  for pkg in nimble:
    let pkgName = pkg.getStr().replace("install ", "").replace("develop ", "")
    echo "trying get latest " & pkgName
    let pkgCmd = pkg.getStr().strip
    if pkgCmd.startsWith("install"):
      let cmd = @["nimble", "-y", pkgCmd].join(" ")
      echo cmd
      cmd.shell
    
    elif pkgCmd.startsWith("develop"):
      if isInPlatform("windows"):
        let cmd = @["cd", "/D", devpkgsDir,
          "&", "nimble", "-y", pkgCmd].join(" ")
        echo cmd
        cmd.shell

      else:
        let cmd = @["cd", devpkgsDir,
          "&&", "nimble", "-y", pkgCmd].join(" ")
        echo cmd
        cmd.shell


proc installLocalDeps(appName: string) =
  #
  # install depedencies in the nimble section
  # nakefile.json
  #
  let nimble = appName.loadJsonNakefile(){"nimble"}{"local"}

  if nimble.isNil:
    echo "no local nimble deps."
    return

  "nimble update".shell
  let workDir = getCurrentDir().joinPath(workingDir(appName))
  let packagesDir = workDir.joinPath("packages")
  let nimbleDir = packagesDir.joinPath("nimble")
  let devpkgsDir = nimbleDir.joinPath("devpkgs")
  
  if not packagesDir.dirExists:
    packagesDir.createDir
  
  if not nimbleDir.dirExists:
    nimbleDir.createDir
  
  if not devpkgsDir.dirExists:
    devpkgsDir.createDir

  if packagesDir.dirExists and nimbleDir.dirExists:
    for pkg in nimble:
      let pkgName = pkg.getStr().replace("install ", "").replace("develop ", "")
      echo "trying get latest " & pkgName
      let pkgCmd = pkg.getStr().strip
      if isInPlatform("windows"):
        if pkgCmd.startsWith("install"):
          let cmd = @["cd", "/D", packagesDir,
            "&", "nimble", "--localdeps", &"--nimbleDir:{nimbleDir}", "-y", pkgCmd].join(" ")
          echo cmd
          cmd.shell
       
        elif pkgCmd.startsWith("develop"):
          let cmd = @["cd", "/D", devpkgsDir,
            "&", "nimble", "--localdeps", &"--nimbleDir:{nimbleDir}", "-y", pkgCmd].join(" ")
          echo cmd
          cmd.shell

      else:
        if pkgCmd.startsWith("install"):
          let cmd = @["cd", packagesDir,
            "&&", "nimble", "--localdeps", &"--nimbleDir:{nimbleDir}", "-y", pkgCmd].join(" ")
          echo cmd
          cmd.shell
       
        elif pkgCmd.startsWith("develop"):
          let cmd = @["cd", devpkgsDir,
            "&&", "nimble", "--localdeps", &"--nimbleDir:{nimbleDir}", "-y", pkgCmd].join(" ")
          echo cmd
          cmd.shell

  else:
    echo &"directory {packagesDir} not exist."
    echo &"directory {nimbleDir} not exist."

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
  if templatesDir.dirExists:
    echo ""
    for kind, path in templatesDir.walkDir:
      if kind == PathComponent.pcDir:
        let f = path.joinPath(jsonNakefile)
        if f.fileExists:
          let appInfo = f.parseFile(){"appInfo"}
          if not appInfo.isNil and appInfo.hasKey("appType") and
            appInfo.hasKey("appDesc"):
            echo appInfo{"appType"}.getStr & " -> " & appInfo{"appDesc"}.getStr
    echo ""

# this will read from templates nakefile.json
# .templates/appType/nakefile.json
# and will process init section
proc newApp(
  appName: string,
  appType: string) =

  let appDir = appsDir.joinPath(appName)

  if appName.isAppExists():
    echo &"App {appName} already exist."
    return

  if appType.existsTemplates():
    # load json from templates
    let fpath = templatesDir.joinPath(appType, jsonNakefile)
    if fileExists(fpath):
      let f = fpath.open(FileMode.fmRead)
      #var fcontent = f.readAll().replace("{appName}", appName)
      var fcontent = f.readAll()
      f.close()

      var jnode = fcontent.parseJson()
      if not isNil(jnode):
        jnode["appInfo"]["appName"] = %appName
        jnode["appInfo"]["appId"] = % $(&"{getTime().toUnix}{appName}")
          .secureHash
        jnode["appInfo"]["appType"] = %appType
        fcontent = $jnode

        var varnode = jnode{"initVar"}
        var initNode = jnode{"init"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        varnode = jnode{"appInfo"}
        if not varnode.isNil:
          varnode = varnode.subtituteVar()
          for k, v in varnode:
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        # replace templates and apps dir definition
        # this defined in the base nakefile.json
        initNode = ($initNode).replace("{templatesDir}", templatesDir).parseJson
        initNode = ($initNode).replace("{appsDir}", appsDir).parseJson
        jnode["init"] = initNode.copy

        #jnode = fcontent.parseJson()
        initnode = jnode{"init"}
        if not initnode.isNil and initnode.kind == JsonNodeKind.JArray:
          ($initNode).replace("::", $DirSep)
            .replace("{appName}", appName).parseJson().doActionList
          if appDir.dirExists:
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

task "templates", "show available app templates.":
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
    if appName.match(re"([a-zA-Z\d_]+)*$", appNameMatch):
      appName.newApp(appType)
    else:
      echo ""
      echo "application name is not valid, only a-zA-Z0-9_"
      echo "example valid name:"
      echo "-> my_blog"
      echo "-> MyBlog"
      echo "-> my_blog32"
      echo "-> My_Blog2"
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

  if appsDir.dirExists:
    echo ""
    for dir in joinPath(appsDir, "*").walkDirs:
      if dir.joinPath(jsonNakefile).fileExists:
        echo "-> " & dir.extractFilename()
    echo ""

task "delete-app", "delete app. Ex: nake delete-app appName.":
  if not true.isUmbrellaMode():
    return

  if cmdParams.len > 1:
    for i in 1..cmdParams.high():
      let appDir = appsDir.joinPath(cmdParams[i])
      if appDir.dirExists:
        appDir.removeDir
        if not appDir.dirExists:
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

task "install-localdeps", "install nimble app depedencies in local env. Ex: nake install-localdeps [appName].":
  let defApp = defaultApp()

  if cmdParams.len > 1:
    let appName = cmdParams[1]
    appName.installLocalDeps()

  elif defApp.appName.isAppExists() or not isUmbrellaMode():
    defApp.appName.installLocalDeps()

  else:
    echo ""
    echo "invalid arguments."
    echo ""

task "install-globaldeps", "install nimble app depedencies in global env. Ex: nake install-globaldeps [appName].":
  let defApp = defaultApp()

  if cmdParams.len > 1:
    let appName = cmdParams[1]
    appName.installGlobalDeps()

  elif defApp.appName.isAppExists() or not isUmbrellaMode():
    defApp.appName.installGlobalDeps()

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
  ## if appName.workingDir not equal "." or ""
  ## then set nwatchdog workdir to appName.workingDir

  var appCollectionsDir = "apps"
  if appName.workingDir notin ["", "."]:
    watchDog.workdir = appName.workingDir
  else:
    if appName.workingDir == ".":
      appCollectionsDir = "../"
    elif appName.workingDir == "":
      appCollectionsDir = "..\\"
 
  if not taskList.isNil and taskList.kind == JsonNodeKind.JArray:
    task name, desc:
      let actionToDo = ($taskList).replace("::", $DirSep)
        .replace("{workingDir}", appName.workingDir)
        .replace("{appName}", appName)
        .replace("{appId}", appInfo(appName).appId)
        .replace("{appVersion}", appInfo(appName).appVersion)
        .replace("{appCollectionsDir}", appCollectionsDir).parseJson
      actionToDo.doActionList
  else:
    echo &"invalid task list {name} , should be in JArray."

if appName.isAppExists():
  var jnode = appName.loadJsonNakefile()
  if not jnode.hasKey("init") and
    not jnode.hasKey("initVar"):
    
    ##  get var section and replace as subtitution
    var vars = jnode{"var"}
    var jnodeStr = $jnode
    if not vars.isNil:
      vars = vars.subtituteVar
      for k, v in vars:
        jnodeStr = jnodeStr.replace("{" & k & "}", v.getStr)

    for k, v in jnodeStr.parseJson:
      if k in ["appInfo", "nimble", "var"]:
        continue
      var desc = v{"desc"}.getStr
      if desc == "": desc = k
      let actionList = v{"tasks"}
      k.addNakeTask(desc, actionList)
