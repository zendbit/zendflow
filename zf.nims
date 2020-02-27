#[
    ZendFlow web framework for nim language
    This framework if free to use and to modify
    License: BSD
    Author: Amru Rosyada
    Email: amru.rosyada@gmail.com
    Git: https://github.com/zendbit
]#

from os import joinPath, DirSep
import strutils

let projectDir = "projects"

proc run(sourceDir, sourceToCompile, sourceJsDir, sourceJsToCompile,
        sourceJsOutputDir: string) =
    var quit = false

    while true:
        var stopCompile = false

        # compile js source
        if not quit:
            let compile = gorgeEx("nim js " & sourceJsToCompile)
            echo compile.output
            if compile.exitCode != 0:
                stopCompile = true

            # move the js output to output dir
            if not stopCompile:
                for jsFile in listFiles(sourceJsDir):
                    if jsFile.endsWith(".js"):
                        let filename = rSplit(jsFile, DirSep, 1)
                        mvFile(jsFile, joinPath(sourceJsOutputDir, filename[
                                high(filename)]))


        let appName = rSplit(sourceToCompile, DirSep, 1)[1].replace(
                        ".nim", "")
        let checkRunning = gorgeEx("ps ax|grep ./" & appName)
        if not stopCompile:
            # kill the app ro restart
            if checkRunning.exitCode == 0:
                for runningAppPId in checkRunning.output.split('\n'):
                    let pid = runningAppPId.strip().split(' ')[0].strip()
                    discard gorgeEx("kill -9 " & pid)

        # if quit break after kill the server proccess
        if quit: break

        if not stopCompile:
            let compile = gorgeEx("nim c " & sourceToCompile)
            echo compile.output
            if compile.exitCode == 0:
                cd(joinPath(thisDir(), sourceDir))
                exec ("./" & appName & "&")

        let input = readLineFromStdin()

        case input
        of "q":
            quit = true
        else:
            echo "input not valid, valid input:"
            echo "hit everything for recompile and run :-)"
            echo "q: for quit"

proc newProject(sourceDir, sourceToCompile, sourceJsDir,
        sourceJsToCompile, sourceJsOutputDir: string) =
    echo sourceDir
    echo sourceToCompile
    echo sourceJsDir
    echo sourceJsToCompile
    echo sourceJsOutputDir
    let staticIndexHtml = joinPath(rSplit(sourceJsOutputDir, DirSep, 1)[0], "index.html")
    let sourceZfTplToCompile = joinPath(sourceDir, "zfTpl.nim")
    let sourceZfJsTplToCompile = joinPath(sourceJsDir, "zfTpl.nim")
    mvFile(sourceZfTplToCompile, sourceToCompile)
    mvFile(sourceZfJsTplToCompile, sourceJsToCompile)
    let outputCompiledJsName = rSplit(sourceJsToCompile, DirSep, 1)[1].replace(
            ".nim", ".js")
    writeFile(staticIndexHtml, staticRead(staticIndexHtml).replace("zfTpl.js",
            outputCompiledJsName))

proc installDeps(sourceDir: string) =
    let depsFile = joinPath(sourceDir, "deps")
    if fileExists(depsFile):
        let deps = staticRead(depsFile)
        for dep in deps.split("\n"):
            var stripDep = dep.strip()
            if not stripDep.startsWith("#") and stripDep != "":
                stripDep = stripDep.split("#")[0].strip()
                let installDepsResult = gorgeEx("echo \"y\" | nimble install " & stripDep)
                echo installDepsResult.output

proc verifyCmd(cmdType: string) =
    cd(thisDir())

    let cmdParts = cmdType.split(':')

    let appName = cmdParts[1]

    # nim source to compile
    let sourceDir = joinPath(projectDir, appName)
    let sourceToCompile = joinPath(sourceDir, appName & "App.nim")

    # nim js source to compile
    let sourceJsDir = joinPath(sourceDir, "nimjs")
    let sourceJsOutputDir = joinPath(sourceDir, "www", "js")
    let sourceJsToCompile = joinPath(sourceJsDir, appName & "Js.nim")

    case cmdParts[0]

    of "run":
        run(sourceDir = sourceDir, sourceToCompile = sourceToCompile,
                sourceJsDir = sourceJsDir,
                sourceJsToCompile = sourceJsToCompile,
                sourceJsOutputDir = sourceJsOutputDir)

    of "new":
        newProject(sourceDir = sourceDir, sourceToCompile = sourceToCompile,
                sourceJsDir = sourceJsDir,
                sourceJsToCompile = sourceJsToCompile,
                sourceJsOutputDir = sourceJsOutputDir)

    of "install":
        if cmdParts[2] == "deps":
            installDeps(sourceDir)
        else:
            echo "Command not found " & cmdParts[0] & " " & cmdParts[1]

    else:
        echo "command not found"

let cmdCount = paramCount()

if cmdCount == 3:
    case paramStr(2)
    of "run":
        verifyCmd("run:" & paramStr(3))

    of "new":
        let appDir = joinPath(projectDir, paramStr(3))
        let zfTplDir = joinPath("zfCore", "zfTpl")
        if not dirExists(appDir):
            cpDir(zfTplDir, appDir)
            verifyCmd("new:" & paramStr(3))

        else:
            echo appDir & " already exist."

    else:
        echo "Command " & paramStr(2) & " not found."

if cmdCount == 4:
    case paramStr(2)
    of "install":
        verifyCmd("install:" & paramStr(3) & ":" & paramStr(4))
    else:
        echo "Command " & paramStr(2) & " not found."
