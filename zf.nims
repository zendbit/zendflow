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

# project folder
let projectDir = "projects"

proc echoRunHelp() =
    echo ""
    echo "hit enter/return for recompile and run :-)"
    echo "q: for quit"
    echo ""

# procedur for run app
proc run(sourceDir, sourceToCompile, sourceJsDir, sourceJsToCompile,
        sourceJsOutputDir: string, build:bool = false) =

    var quit = false

    while true:
        cd(thisDir())
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
                        echo jsFile
                        let filename = rSplit(jsFile, DirSep, 1)
                        let targetFile = joinPath(sourceJsOutputDir, filename[
                                high(filename)])
                        if fileExists(targetFile):
                            rmFile(targetFile)
                        mvFile(jsFile, targetFile)


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
            if compile.exitCode == 0 and not build:
                cd(joinPath(thisDir(), sourceDir))
                exec ("./" & appName & "&")
                echoRunHelp()

            if build:
                break

        let input = readLineFromStdin()
        case input
        of "q":
            quit = true
        else:
            echo "input not valid, valid input:"
            echoRunHelp()

proc echoNewProjectHints(sourceDir: string) =
    echo ""
    echo "Project created " & sourceDir
    echo ""
    echo "- run this command to install the project depedency: "
    echo " $> nim zf.nims install " & rSplit(sourceDir, DirSep, 1)[1] & " deps"
    echo ""
    echo "if you plan to modify the depedency of project you can modify the deps file"
    echo "or you can directly using nimble to download the package"
    echo ""
    echo "- run this command to run the project: "
    echo " $> nim zf.nims run " & rSplit(sourceDir, DirSep, 1)[1]
    echo " "
    echo "The run command will not exit but wait for user key input,"
    echo "- hit return/enter to recompile the modified source"
    echo "- enter q then hit return/enter to quit from the app and stop the server"
    echo ""

# procedure for new project
proc newProject(sourceDir, sourceToCompile, sourceJsDir,
        sourceJsToCompile, sourceJsOutputDir, staticIndexHtml: string) =
    let sourceZfTplToCompile = joinPath(sourceDir, "zfTpl.nim")
    let sourceZfJsTplToCompile = joinPath(sourceJsDir, "zfTpl.nim")
    mvFile(sourceZfTplToCompile, sourceToCompile)
    mvFile(sourceZfJsTplToCompile, sourceJsToCompile)
    let outputCompiledJsName = rSplit(sourceJsToCompile, DirSep, 1)[1].replace(
            ".nim", ".js")
    writeFile(staticIndexHtml, staticRead(staticIndexHtml).replace("zfTpl.js",
            outputCompiledJsName))

    if dirExists(sourceDir):
        echoNewProjectHints(sourceDir)

    else:
        echo ""
        echo "Failed to create project " & sourceDir
        echo ""


# procedur for install deps
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

# verify command parameter and define the action
proc verifyCmd(cmdType: string) =

    let cmdParts = cmdType.split(':')

    let appName = cmdParts[1]

    # nim source to compile
    let sourceDir = joinPath(projectDir, appName)
    let sourceToCompile = joinPath(sourceDir, appName & "App.nim")

    # nim js source to compile
    let sourceJsDir = joinPath(sourceDir, "nimjs")
    let sourceJsOutputDir = joinPath(sourceDir, "www", "private", "js", "compiled")
    let sourceJsToCompile = joinPath(sourceJsDir, appName & "Js.nim")
    let staticIndexHtml = joinPath(sourceDir, "www", "index.html")

    case cmdParts[0]

    of "run":
        run(sourceDir = sourceDir, sourceToCompile = sourceToCompile,
            sourceJsDir = sourceJsDir, sourceJsToCompile = sourceJsToCompile,
            sourceJsOutputDir = sourceJsOutputDir)

    of "new":
        newProject(sourceDir = sourceDir, sourceToCompile = sourceToCompile,
            sourceJsDir = sourceJsDir, sourceJsToCompile = sourceJsToCompile,
            sourceJsOutputDir = sourceJsOutputDir, staticIndexHtml= staticIndexHtml)

    of "build":
        run(sourceDir = sourceDir, sourceToCompile = sourceToCompile,
            sourceJsDir = sourceJsDir, sourceJsToCompile = sourceJsToCompile,
            sourceJsOutputDir = sourceJsOutputDir, build = true)

    of "install":
        if cmdParts[2] == "deps":
            installDeps(sourceDir)
        else:
            echo "Command not found " & cmdParts[0] & " " & cmdParts[1]

    else:
        echo "command not found"

# code will start form here to filter the command parameter count
# and command line argements
let cmdCount = paramCount()

if cmdCount == 3:
    case paramStr(2)
    of "run":
        verifyCmd("run:" & paramStr(3))

    of "build":
        verifyCmd("build:" & paramStr(3))

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
