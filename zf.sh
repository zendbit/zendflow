#!/bin/bash

#
# ZendFlow web framework for nim language
# This framework if free to use and to modify
# License: BSD
# Author: Amru Rosyada
# Email: amru.rosyada@gmail.com
# Git: https://github.com/zendbit
#

# retrieve command param
CMD=$1
APPNAME=$2

# project directory
WORK_DIR=`pwd`
PROJECT_DIR=$WORK_DIR/"projects"
APP_DIR=$PROJECT_DIR/$APPNAME

# if in current dir has appnameApp.nim
# then assume using local zf.sh
if [ -f $APPNAME"App.nim" ]
then
    PROJECT_DIR=$WORK_DIR
    APP_DIR=$WORK_DIR
elif [ ! -d $PROJECT_DIR ]
then
    mkdir -p $PROJECT_DIR
fi

setCmdParam(){
    sourceDir=$1
    sourceToCompile=$2
    sourceJsDir=$3
    sourceJsToCompile=$4
    sourceJsOutputDir=$5
    build=$6
    staticIndexHtml=$7
}

unsetCmdParam(){
    unset sourceDir
    unset sourceToCompile
    unset sourceJsDir
    unset sourceJsToCompile
    unset sourceJsOutputDir
    unset build
    unset staticIndexHtml
}

showRunHelp(){
    echo ""
    echo "hit enter/return for recompile and run :-)"
    echo "q: for quit"
    echo ""
}

showNewProjectHints(){
    echo ""
    echo "Project created $sourceDir"
    echo ""
    echo "- run this command to install the project depedency: "
    echo " $> ./zf.sh install ${sourceDir##*/} deps"
    echo ""
    echo "if you plan to modify the depedency of project you can modify the deps file"
    echo "or you can directly using nimble to download the package"
    echo ""
    echo "- run this command to run the project: "
    echo " $> ./zf.sh run ${sourceDir##*/}"
    echo " "
    echo "The run command will not exit but wait for user key input,"
    echo "- hit return/enter to recompile the modified source"
    echo "- enter q then hit return/enter to quit from the app and stop the server"
    echo ""
}

showFailedCreateProject(){
    echo ""
    echo "Failed to create project $sourceDir"
    echo ""
}

showFailedCreateJsOutputDir(){
    echo ""
    echo "Failed to create $sourceJsOutputDir directory."
    echo ""
}

showFailedAppNotFound(){
    echo ""
    echo "application not found $sourceDir"
    echo "create new application using:"
    echo "  $>./zf.sh new appname"
    echo ""
}

showInvalidCmd(){
    echo ""
    echo "Invalid command $CMD $APPNAME"
    echo ""
}

showInvalidAppName(){
    echo ""
    echo "$appDir already exist, try another appname."
    echo ""
}

showInvalidNewCmd(){
    echo ""
    echo "Invalid command new $APPNAME"
    echo ""
}

showInvalidInstallCmd(){
    echo ""
    echo "Invalid command install $APPNAME $3"
    echo ""
}

showNotAllowedCmd(){
    echo ""
    echo "Command not allowed."
    echo ""
}

# run command
runCmd(){
    local quit=0

    while [ 1 ]
    do
        cd $WORK_DIR
        local stopCompile=0

        if [ $quit -eq 0 ]
        then
            nim "js" $sourceJsToCompile

            stopCompile=$?

            if [ $stopCompile -eq 0 ]
            then
                for file in $sourceJsDir/*.js
                do
                    local destFile=${file//$sourceJsDir/$sourceJsOutputDir}
                    mv $file $destFile
                done
            fi
        fi

        if [ $stopCompile -eq 0 ]
        then
            ps -ef | grep "./$APPNAME" | awk '{print $2}' | xargs kill -9 \
            && echo "Server killed." || echo "Server not running."
        fi

        if [ $quit -eq 1 ]
        then
            exit
        fi

        if [ $stopCompile -eq 0 ]
        then
            nim "c" "-d:ssl" $sourceToCompile

            stopCompile=$?

            if [ $stopCompile -eq 0 ]
            then
                if [ $build -eq 0 ]
                then
                    #cd $PROJECT_DIR/$APPNAME
                    cd $APP_DIR
                    exeAppName=${sourceToCompile##*/}
                    ./${exeAppName//.nim/""} &
                    showRunHelp
                else
                    exit
                fi
            fi
        fi

        read input
        case $input in
            q)
                quit=1
                ;;
            *)
                ;;
        esac
    done
}

newProjectCmd(){
    local sourceZfTplToCompile=$sourceDir/"zfTpl.nim"
    local sourceZfJsTplToCompile=$sourceJsDir/"zfTpl.nim"
    mv $sourceZfTplToCompile $sourceToCompile
    mv $sourceZfJsTplToCompile $sourceJsToCompile
    local outputCompiledJsName=${sourceJsToCompile##*/}
    outputCompiledJsName=${outputCompiledJsName//".nim"/".js"}
    local staticIndexHtmlTmp=$staticIndexHtml".tmp"
    sed 's/zfTpl.js/'$outputCompiledJsName'/g' $staticIndexHtml > $staticIndexHtmlTmp
    mv $staticIndexHtmlTmp $staticIndexHtml

    if [ -d $sourceDir ]
    then
        showNewProjectHints
    else
        showFailedCreateProject
    fi
}

installDeps(){
    local depsFile=$sourceDir/"deps"
    local depsFolder=$WORK_DIR/"nimbleDeps"

    if [ ! -d $depsFolder ]
    then
        mkdir $depsFolder
    fi

    cd $depsFolder

    if [ -f $depsFile ]
    then
        nimble update
        while IFS="\n" read -r line
        do
            local stripLine=`echo $line`
            local comntChar=${stripLine:0:1}
            local re='([ a-zA-Z0-9_\-\.>\=<]+)'
            if [ "$comntChar" != "#" ] && \
                [ "$comntChar" != "" ] && \
                [[ $stripLine =~ $re ]]
            then
                local depNimble=${BASH_REMATCH[0]}
                local nimCmd=`echo $depNimble | cut -d " " -f 1`
                local nimDepPkg=`echo $depNimble | cut -d " " -f 2`

                echo "Collecting $nimDepPkg"
                echo "---------------------"

                local installedDep=`nimble list -i|grep $nimDepPkg`
                if [ "$installedDep" == "" ]
                then
                    case $nimCmd in
                        install)
                            echo "y" | nimble install $nimDepPkg
                            ;;
                        develop)
                            echo "y" | nimble develop $nimDepPkg
                            ;;
                    esac

                else
                    echo "Dependency already exist!"
                    echo $installedDep
                    echo `nimble path $nimDepPkg`
                fi

                echo "---------------------"
                echo ""
            fi
        done < $depsFile
    fi

    cd $WORK_DIR
}

# verify command action
# parameter $1 is type of command ex, run:appname:...
verifyCmd(){
    if [ "$CMD" != "" ] && [ "$APPNAME" != "" ]
    then
        #sourceDir=$PROJECT_DIR/$APPNAME
        sourceDir=$APP_DIR
        echo $sourceDir

        if [ -d $sourceDir ]
        then
            local sourceToCompile=$sourceDir/$APPNAME"App.nim"

            local sourceJsDir=$sourceDir"/client"
            local sourceJsOutputDir=$sourceDir"/www/private/js/compiled"
            if [ ! -d $sourceJsOutputDir ]
            then
                mkdir $sourceJsOutputDir
                if [ ! $? -eq 0 ]
                then
                    showFailedCreateJsOutputDir
                fi
            fi

            local sourceJsToCompile=$sourceJsDir/$APPNAME"Js.nim"
            local staticIndexHtml=$sourceDir"/www/index.html"

            setCmdParam $sourceDir \
                $sourceToCompile \
                $sourceJsDir \
                $sourceJsToCompile \
                $sourceJsOutputDir \
                0 \
                $staticIndexHtml

            case $CMD in
                run)
                    runCmd
                    ;;
                build)
                    build=1
                    runCmd
                    ;;
                new)
                    newProjectCmd
                    ;;
                install)
                    if [ "$3" == "deps" ]
                    then
                        installDeps
                    fi
                    ;;
                *)
                    ;;
            esac

            unsetCmdParam

        else
            showFailedAppNotFound
        fi
    else
        showInvalidCmd
    fi
}

# parse command
main(){
    case $CMD in
        run)
            verifyCmd "run" $APPNAME
            ;;
        build)
            verifyCmd "build" $APPNAME
            ;;
        new)
            if [ -f $APPNAME"App.nim" ]
            then
                showNotAllowedCmd
                return
            fi

            if [ "$APPNAME" != "" ]
            then
                #local appDir=$PROJECT_DIR/$APPNAME
                local appDir=$APP_DIR
                local zfTplDir="zfTpl"
                if [ ! -d $appDir ]
                then
                    cp -r $zfTplDir $appDir
                    cp "zf.sh" $appDir
                    verifyCmd "new" $APPNAME
                else
                    showInvalidAppName
                fi
            else
                showInvalidNewCmd
            fi
            ;;
        install)
            if [ "$3" == "deps" ]
            then
                verifyCmd "install" $APPNAME $3
            else
                showInvalidInstallCmd
            fi
            ;;
        *)
            showInvalidCmd
            ;;
    esac
}

# call main script
main $@
