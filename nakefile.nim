##
##  nakefile.nim
##  the nake build system
##  will parse the nakefile.json into nake task
##
##  @author: Amru Rosyada
##  @email: amru.rosyada@gmail.com
##  @license: BSD
##

import NWatchdog

import
  nake,
  nakelib,
  os,
  strutils,
  strformat,
  json,
  osproc,
  distros,
  times,
  checksums/sha1,
  regex,
  sequtils

var cmdLineParams {.threadvar.}: seq[string]
cmdLineParams = commandLineParams()

var cmdParams {.threadvar.}: seq[string]
var cmdOptions {.threadvar.}: seq[string]

for clp in cmdLineParams:
  if clp.startsWith("-"):
    cmdOptions.add(clp)
  else:
    cmdParams.add(clp)

var appsDir {.threadvar.}: string
var templatesDir {.threadvar.}: string
var nakefileNode {.threadvar.}: JsonNode
var watchDog {.threadvar.}: NWatchDog[JsonNode]
watchDog = NWatchDog[JsonNode](interval: 100)

const
  jsonNakefile = "nakefile.json"

# init appsDir and templatesDir
# depend on the top level of the nakefile.json
if jsonNakefile.fileExists:
  let jNode = jsonNakefile.parseFile()
  if not jNode{"appsDir"}.isNil:
    appsDir = jNode{"appsDir"}
      .getStr()
      .replace("::", $DirSep)

  if not jNode{"templatesDir"}.isNil:
    templatesDir = jNode{"templatesDir"}
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
    if filter != "" and not src.match(re2 filter):
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
        not fileInfo.tail.match(re2 filter):
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

proc isInPlatform(platform: string): bool {.gcsafe.} =
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
  {.gcsafe.}:
    case platform.toLower
    of ($Windows).toLower:
      result = detectOs(Windows)
    of ($Posix).toLower:
      result = detectOs(Posix)
    of ($MacOSX).toLower:
      result = detectOs(MacOSX)
    of ($BSD).toLower:
      result = detectOs(BSD)

proc isUmbrellaMode(showMsg: bool = false): bool {.gcsafe.} =
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

proc escapePattern(patternStr: string): string {.gcsafe.} =
  result = patternStr
  # check if pattern have to escaped the string
  for rgx in result.findAll(re2"(``.*?``)"):
    let strMatch = result[rgx.group(0)]
    result = result.replace(strMatch, strMatch.subStr(2, strMatch.len - 3).escapeRe)

proc subtituteVar(varNode: JsonNode): JsonNode {.gcsafe.} =
  # this function will subtitute variable
  # defined int the nakefile.json
  # ex:
  # {"foo": "hello", "bar": "{foo} world"}
  # into {"foo": "hello", "bar": "hello world"}
  result = %*{}
  for k, v in varNode:
    var svar = v.getStr()
    for regexMatch in svar.findAll(re2"({[\w\W]+})"):
      if regexMatch.captures.len == 0: continue
      let s = svar[regexMatch.group(0)]
      let svarname = s.replace("{", "").replace("}", "")
      let svarvalue = result{svarname}.getStr()
      if svarvalue == "":
        continue
      svar = svar.replace(s, svarvalue)

    result[k] = %svar

proc cleanDoubleColon(str: string): string {.gcsafe.} =
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

proc workingDir(appName: string): string {.gcsafe.} =
  #
  # get current app dir with given appname
  #
  result = getAppDir()
  if appsDir != "":
    result = result.joinPath(appsDir, appName)

proc loadJsonNakefile(appName: string = ""): JsonNode {.gcsafe.} =
  #
  # load nakefile.json
  #
  try:
    if appsDir.joinPath(appName, jsonNakefile).fileExists:
      result = appsDir.joinPath(appName, jsonNakefile).parseFile()
    elif jsonNakefile.fileExists:
      result = jsonNakefile.parseFile()

    var appInfo = result{"appInfo"}
    var vars = result{"var"}
    var tmpJsonNakefile = $result
    if not appInfo.isNil:
      appInfo = appInfo.subtituteVar()
      for k, v in appInfo:
        tmpJsonNakefile = tmpJsonNakefile.replace("{" & k & "}", v.getStr())

    if not vars.isNil:
      vars = vars.subtituteVar()
      for k, v in vars:
        tmpJsonNakefile = tmpJsonNakefile.replace("{" & k & "}", v.getStr())

    tmpJsonNakefile = tmpJsonNakefile
      .replace("::", $DirSep)
      .replace("{workingDir}", appName.workingDir())
    result = tmpJsonNakefile.parseJson()

  except Exception:
    discard

proc moveDirContents(src: string,
  dest: string,
  mode: FileOperationMode = COPY_MODE,
  fileOnly: bool = false,
  filter: string = "",
  withStructure: bool = true,
  structureOffset: string = "",
  recursive: bool = true) {.gcsafe.} =
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
  ) {.gcsafe.} =

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
      if not pathSrc.match(re2 filter):
        continue
    
    if kind == pcFile or kind == pcLinkToFile:
      pathSrc.removeFile

    else:
      pathSrc.removeDir

proc appInfo(name: string = ""): tuple[
  appName: string,
  appId: string,
  appType: string,
  appVersion: string] {.gcsafe.} =

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

  result = (appName, appId, appType, appVersion)

proc defaultApp(): tuple[
  appName: string,
  appId: string,
  appType: string,
  appVersion: string] {.gcsafe.} =

  #
  # get default app
  # return tupple with appName and appType
  #
  
  result = appInfo()

proc setDefaultApp(appName: string): bool {.gcsafe.} =
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

#
# make nake run with nakefile.json task description
# this make more portable
#
var defApp: tuple[
  appName: string,
  appId: string,
  appType: string,
  appVersion: string]
defApp = defaultApp()

var appName {.threadvar.}: string
appName = defApp.appName

if cmdParams.len > 1:
  appName = cmdParams[1]

proc doActionList(actionList: JsonNode) {.gcsafe.} =
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

              elif not next.isNil and next.kind == JsonNodeKind.JArray:
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

        elif not next.isNil and next.kind == JsonNodeKind.JArray:
          next.doActionList

      of "replaceStr":
        let desc = action{"desc"}
        if not desc.isNil:
          echo desc.getStr()

        let list = action{"list"}
        var errMsg = ""

        if not list.isNil and list.kind == JsonNodeKind.JArray:
          for l in list:
            let files = l{"files"}
            let next = action{"next"}
            let replace = l{"replace"}
            let err = action{"err"}

            if not files.isNil:
              for file in files:

                echo &"replace str in files -> {files}"

                if file.getStr().fileExists:
                  try:
                    var f = file.getStr()
                      .open(FileMode.fmRead)
                    var fstr = f.readAll()
                    f.close()

                    if not replace.isNil:

                      for k, v in replace:
                        echo &" {k} -> {v}"


                        # find rgx on pattern then escape it
                        let regReplaceStr = k.cleanDoubleColon.escapePattern

                        fstr = fstr.replace(
                          re2 regReplaceStr,
                          v.getStr().cleanDoubleColon()
                          )

                      f = file.getStr()
                        .open(FileMode.fmWrite)
                      f.write(fstr)
                      f.close()

                  except Exception as ex:
                    errMsg = ex.msg

                  if errMsg != "":
                    echo errMsg
                    if not err.isNil and err.kind == JsonNodeKind.JArray:
                      err.doActionList

                  elif not next.isNil and next.kind == JsonNodeKind.JArray:
                    next.doActionList

        let next = action{"next"}
        if errMsg == "" and not next.isNil and next.kind == JsonNodeKind.JArray:
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

              elif not next.isNil and next.kind == JsonNodeKind.JArray:
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
                    let eventsList = param{"events"}
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
                        if file.match(re2 pattern):
                          ($onModified)
                            .replace("{modifiedFilePath}", file)
                            .replace("{modifiedFileDir}", dir)
                            .replace("{modifiedFileName}", name & ext)
                            .parseJson
                            .doActionList
                    of Created:
                      if not onCreated.isNil:
                        if file.match(re2 pattern):
                          ($onCreated)
                            .replace("{createdFilePath}", file)
                            .replace("{createdFileDir}", dir)
                            .replace("{createdFileName}", name & ext)
                            .parseJson
                            .doActionList
                    of Deleted:
                      if not onDeleted.isNil:
                        if file.match(re2 pattern):
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

proc isAppExists(appName: string): bool {.gcsafe.} =
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

proc getNimblePkgInfo(pkgName: string): tuple[pkgUrl, repoType: string] =
  let pkgNameTmp = pkgName.split("==")[0]
    .split(">")[0]
    .split("<")[0]
    .split("=")[0]
    .split("@")[0]
    .strip()
  var res = execCmdEx(&"""nimble search {pkgNameTmp}""")
  var pkgUrl = ""
  var repoType = ""
  if res.exitCode == 0:
    for line in res.output.split("\n"):
      var cleanLine = line.strip
      if cleanLine.startsWith("url:"):
        let pkgUrlParts = cleanLine.replace("url:", "").strip.split("(")
        pkgUrl = pkgUrlParts[0].strip()
        repoType = pkgUrlParts[1].replace(")", "").strip()

  result = (pkgUrl, repoType)

proc initInstallDeps(appName: string): tuple[workDir, packagesDir, nimbleDir, nimblePackagesDir, nimbleDevPackagesDir: string] =
  let workDir = workingDir(appName)
  let packagesDir = workDir.joinPath(".packages")
  let nimbleDir = packagesDir.joinPath("nimble")
  let nimblePackagesDir = nimbleDir.joinPath("pkgs2")
  let nimbleDevPackagesDir = nimbleDir.joinPath("devPkgs")

  if not packagesDir.dirExists:
    packagesDir.createDir

  if not nimbleDir.dirExists:
    nimbleDir.createDir

  if not nimblePackagesDir.dirExists:
    nimblePackagesDir.createDir

  if not nimbleDevPackagesDir.dirExists:
    nimbleDevPackagesDir.createDir

  result = (workDir, packagesDir, nimbleDir, nimblePackagesDir, nimbleDevPackagesDir)

proc depsStrToParts(depsStr: string): tuple[pkgType, pkgUrl, pkgTag, repoType: string] =
  var pkgType, pkgUrl, pkgTag, repoType: string
  var regexMatch: RegexMatch2
  if depsStr.match(re2 "([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+).*$", regexMatch):
    pkgType = depsStr[regexMatch.group(0)]
    pkgUrl = depsStr[regexMatch.group(1)]
    pkgTag = depsStr[regexMatch.group(2)]
    repoType = depsStr[regexMatch.group(3)]

    return (pkgType, pkgUrl, pkgTag, repoType)

  echo "\n!!!!!!! failed wrong dependency format !!!!!!!\n"
  echo &">> on line: {depsStr}"
  echo "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  quit(-1)

proc installDeps(appName: string) {.gcsafe.} =
  #
  # install depedencies in the nimble section
  # nakefile.json
  #
  let nimble = appName.loadJsonNakefile(){"nimble"}

  if nimble.isNil:
    echo "no nimble deps."
    return

  let depsEnv = initInstallDeps(appName)

  (&"nimble update --nimbleDir:{depsEnv.nimbleDir}").shell
  if depsEnv.packagesDir.dirExists and depsEnv.nimbleDir.dirExists:
    for pkg in nimble:
      let pkgCmdParts = pkg.getStr().depsStrToParts()
      var pkgUrl = ""
      var repoType = ""

      echo ">> trying get " & pkgCmdParts.pkgUrl

      var pkgTag = pkgCmdParts.pkgTag
      let pkgInfo = getNimblePkgInfo(pkgCmdParts.pkgUrl)

      if pkgCmdParts.repoType == "nimblerepo":
        ##
        ##  nimble version using @ for get version
        ##  pkgname@version -> specific tag/branch release
        ##  pkgname@#head -> upstream
        ##
        pkgTag = &"@{pkgCmdParts.pkgTag}"
        if pkgCmdParts.pkgTag == "head":
          pkgTag = &"@#{pkgCmdParts.pkgTag}"
      elif pkgCmdParts.pkgTag != "head":
        ##
        ##  directly from repository git/hg
        ##  using tag/branch version
        ##  append v prefix for specific version
        ##
        pkgTag = "v" & pkgCmdParts.pkgTag

      pkgUrl = pkgCmdParts.pkgUrl
      repoType = pkgCmdParts.repoType

      if pkgInfo.pkgUrl != "":
        pkgUrl = pkgInfo.pkgUrl
        repoType = pkgInfo.repoType

      var packagesDir = depsEnv.packagesDir
      if pkgCmdParts.pkgType == "develop":
        packagesDir = depsEnv.nimbleDevPackagesDir

      var cmd: string
      var osCmd = @["cd", packagesDir, "&&"]
      let pkgName = pkgUrl.splitFile().name

      if isInPlatform("windows"):
        ##
        ##  check if in windows platform
        ##
        osCmd = @["cd", "/D", packagesDir, "&"]

      if not packagesDir.joinPath(pkgName).dirExists():
        if pkgCmdParts.repoType == "nimblerepo":
          cmd = (osCmd & @["nimble", &"--nimbleDir: {depsEnv.nimbleDir}", "-y", pkgCmdParts.pkgType, pkgCmdParts.pkgUrl]).join(" ")
          echo cmd
          cmd.shell

        else:
          var cloneCmd = "git clone"

          if pkgCmdParts.repoType == "hg":
            cloneCmd = "hg clone"

          if pkgCmdParts.pkgTag != "head":
            cloneCmd = &"{cloneCmd} -b {pkgTag}"
            if pkgCmdParts.repoType == "hg":
              cloneCmd = &"{cloneCmd} -u {pkgTag}"

          cmd = (osCmd & @[cloneCmd, pkgCmdParts.pkgUrl]).join(" ")
          echo cmd
          cmd.shell

      else:
        var checkoutCmd = "git checkout"

        if pkgCmdParts.repoType == "hg":
          checkoutCmd = "hg checkout"

        if pkgCmdParts.pkgTag != "head":
          checkoutCmd = &"{checkoutCmd} {pkgTag}"
          if pkgCmdParts.repoType == "hg":
            checkoutCmd = &"{checkoutCmd} {pkgTag}"

        else:
          checkoutCmd = checkoutCmd.replace("checkout", "pull")

        var tmpOsCmd = osCmd[0..osCmd.high]
        tmpOsCmd[tmpOsCmd.high - 1] = tmpOsCmd[tmpOsCmd.high - 1].joinPath(pkgName)
        tmpOsCmd.add(checkoutCmd)
        cmd = (tmpOsCmd).join(" ")
        echo cmd
        cmd.shell

      if pkgCmdParts.pkgType == "develop":
        var tmpOsCmd = osCmd[0..osCmd.high]
        tmpOsCmd[tmpOsCmd.high - 1] = tmpOsCmd[tmpOsCmd.high - 1].joinPath(pkgName)
        cmd = (tmpOsCmd & @["nimble", &"--nimbleDir: {depsEnv.nimbleDir}", "-y", "install"]).join(" ")
        echo cmd
        cmd.shell

      echo "--"
  else:
    echo &"directory {depsEnv.packagesDir} not exist."
    echo &"directory {depsEnv.nimbleDir} not exist."

proc existsTemplates(templates: string, templateName: string): bool {.gcsafe.} =
  #
  # check if template exists
  # available template is in the .template dir
  #
  for kind, path in templatesDir.walkDir:
    if kind == PathComponent.pcDir and
      path.endsWith(DirSep & templateName):
      return true

proc showTemplateList() {.gcsafe.} =
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
  appType: string) {.gcsafe.} =
  let appDir = appsDir.joinPath(appName)

  if appName.isAppExists():
    echo &"App {appName} already exist."
    return

  if templatesDir.existsTemplates(appType):
    # load json from templates
    let fpath = templatesDir.joinPath(appType, jsonNakefile)
    if fileExists(fpath):
      var jNode: JsonNode = fpath.parseFile()
      if not jNode.isNil():
        jNode["appInfo"]["appName"] = %appName
        jNode["appInfo"]["appId"] = % $(&"{getTime().toUnix}{appName}")
          .secureHash
        jNode["appInfo"]["appType"] = %appType

        var varNode = jNode{"initVar"}
        var initNode = jNode{"init"}
        if not varNode.isNil:
          varNode = varNode.subtituteVar()
          for k, v in varNode:
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        varNode = jNode{"appInfo"}
        if not varNode.isNil:
          varNode = varNode.subtituteVar()
          for k, v in varNode:
            initNode = ($initNode).replace("{" & k & "}", v.getStr()).parseJson

        # replace templates and apps dir definition
        # this defined in the base nakefile.json
        initNode = ($initNode).replace("{templatesDir}", templatesDir).parseJson
        initNode = ($initNode).replace("{appsDir}", appsDir).parseJson
        jNode["init"] = initNode.copy
        initNode = jNode{"init"}
        if not initNode.isNil and initNode.kind == JsonNodeKind.JArray:
          ($initNode).replace("::", $DirSep)
            .replace("{appName}", appName).parseJson().doActionList
          if appDir.dirExists:
            # remove from node then save nakefile.json to the appdir
            # remove:
            # init section
            # initVar section
            jNode.delete("init")
            jNode.delete("initVar")
            let f = appDir.joinPath(jsonNakefile).open(FileMode.fmWrite)
            f.write(jNode.pretty(2))
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
    if appName.match(re2"([a-zA-Z\d_]+)*$"):
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

task "install-deps", "install nimble app depedencies in local env. Ex: nake install-deps [appName].":
  appName.installDeps()

task "help", "show available tasks. Ex: nake help.":
  "nake".shell()

proc preparePWA() =
  task "prepare-pwa", "prepare progressive web app resources manifest.json and worker":
    let pwa = appName.loadJsonNakefile(){"pwa"}
    let version = pwa{"version"}
    let cacheName = pwa{"cacheName"}
    let staticResources = pwa{"staticResources"}
    let resourcesOut = pwa{"resourcesOut"}
    let assetWwwDir = pwa{"assetWwwDir"}

    if not version.isNil and
      not cacheName.isNil and
      not staticResources.isNil and
      not resourcesOut.isNil and
      not assetWwwDir.isNil:

      let resOutStr = resourcesOut.getStr()
      let resDirStr = resOutStr.splitFile().dir
      let wwwDirStr = assetWwwDir.getStr()

      if not resDirStr.dirExists():
        resDirStr.createDir()

      var pwaResourcesOut: seq[string]
      pwaResourcesOut.add("##  this autogenerate from building system")
      pwaResourcesOut.add("##  don't edit will override on new build")
      pwaResourcesOut.add(&"const version* = {version}")
      pwaResourcesOut.add(&"const cacheName* = {cacheName}")
      pwaResourcesOut.add("const staticResources*: seq[string] = @[")
      for res in staticResources:
        let resStr = res.getStr()
        if resStr.endsWith(suffix = "/*"):
          for path in wwwDirStr.joinPath(resStr.replace("/*", "")).walkDirRec():
            pwaResourcesOut.add(&"""    "{path.replace(wwwDirStr, "")}",""")

          continue

        pwaResourcesOut.add(&"""    "{resStr}",""")

      pwaResourcesOut.add("  ]")

      let f = open(resOutStr, fmWrite)
      f.write(pwaResourcesOut.join("\n"))
      f.close()

proc addNakeTask(name: string, desc: string, taskList: JsonNode) {.gcsafe.} =
  ## if appName.workingDir not equal "." or ""
  ## then set nwatchdog workdir to appName.workingDir

  if appName.workingDir notin ["", "."]:
    watchDog.workdir = appName.workingDir

  if not taskList.isNil and taskList.kind == JsonNodeKind.JArray:
    {.gcsafe.}:
      task name, desc:
        taskList.doActionList
  else:
    echo &"invalid task list {name} , should be in JArray."

if appName.isAppExists():
  var jNode = appName.loadJsonNakefile()
  if not jNode.hasKey("init") and
    not jNode.hasKey("initVar"):
    
    ##  get var section and replace as subtitution
    var vars = jNode{"var"}
    var jNodeStr = $jNode
    if not vars.isNil:
      vars = vars.subtituteVar
      for k, v in vars:
        jNodeStr = jNodeStr.replace("{" & k & "}", v.getStr)

    jNodeStr = jNodeStr.replace("{workingDir}", appName.workingDir)

    nakefileNode = jNodeStr.parseJson

    ##  padd task prepare-pwa if pwa settings exists
    if not nakefileNode{"pwa"}.isNil:
      preparePWA()

    for k, v in nakefileNode:
      if k in ["appInfo", "nimble", "var", "pwa"]:
        continue
      
      var desc = v{"desc"}.getStr
      ##  if description empty set description to task name
      if desc == "": desc = k
      let actionList = v{"tasks"}
      k.addNakeTask(desc, actionList)
