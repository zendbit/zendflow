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
DEFAULT_APP=".defaultapp"

if [ "$APPNAME" == "" ] && [ -f $DEFAULT_APP ]
then
  read -r APPNAME < $DEFAULT_APP
fi

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

APP_SRC_DIR=$APP_DIR/"src"
APP_SRC2JS_DIR=$APP_DIR/"src2js"

# nim js source compile command
nimJsCompileCmd(){
  nim js -o:JS_OUT_APPNAME $1
}

# nim compile command
nimCompileCmd(){
  nim c -d:ssl -d:nimDebugDlOpen --opt:none -o:$OUT_APPNAME $1
}

# nim compile command
nimCompileReleaseCmd(){
  nim c -d:ssl -d:release -o:$OUT_APPNAME $1
}

# app run command
appRunCmd(){
  ./$1
}

# check if overridecmd.sh exist
OVERRIDE_CMD=$APP_DIR/"overridecmd.sh"
if [ -f $OVERRIDE_CMD ]
then
    source $OVERRIDE_CMD
fi

setCmdParam(){
  if [ $APPNAME != "" ]
  then
    OUT_APPNAME=$APP_DIR/$APPNAME"App"
    SRC_TO_COMPILE=$APP_SRC_DIR/$APPNAME"App.nim"
    JS_SRC_COMPILED_DIR=$APP_DIR/"www/private/js/compiled"
    JS_SRC_TO_COMPILE=$APP_SRC2JS_DIR/$APPNAME"App.nim"
    JS_OUT_APPNAME=$JS_SRC_COMPILED_DIR/$APPNAME"App.js"
    STATIC_INDEX_HTML=$APP_DIR/"www/index.html"
  fi

  BUILD=0
  RELEASE_MODE=0
}

unsetCmdParam(){
  unset SRC_TO_COMPILE
  unset JS_SRC_TO_COMPILE
  unset JS_SRC_COMPILED_DIR
  unset BUILD
  unset STATIC_INDEX_HTML
  unset RELEASE_MODE
}

showRunHelp(){
  echo ""
  echo "------------------------------------------------------"
  echo "Hit enter/return for recompile and run :-)"
  echo "q: for quit"
  echo "------------------------------------------------------"
  echo ""
}

showNewProjectHints(){
  echo ""
  echo "------------------------------------------------------"
  echo "Project created $APP_DIR"
  echo ""
  echo "- run this command to install the project depedency: "
  echo "  $>./zf.sh install-deps ${APP_DIR##*/}"
  echo "------------------------------------------------------"
  echo "If you plan to modify the depedency of project you can modify the deps file"
  echo "or you can directly using nimble to download the package"
  echo "------------------------------------------------------"
  echo "- run this command to run the project: "
  echo "  $>./zf.sh run ${APP_DIR##*/}"
  echo "------------------------------------------------------"
  echo "The run command will not exit but wait for user key input,"
  echo "- hit return/enter to recompile the modified source"
  echo "- enter q then hit return/enter to quit from the app and stop the server"
  echo "------------------------------------------------------"
  echo "For more information about command usage."
  echo "  $>./zf.sh --help"
  echo ""
}

showFailedCreateProject(){
  echo ""
  echo "------------------------------------------------------"
  echo "Failed to create project $APP_DIR"
  echo "------------------------------------------------------"
  echo ""
}

showFailedCreateJsOutputDir(){
  echo ""
  echo "------------------------------------------------------"
  echo "Failed to create $JS_SRC_COMPILED_DIR directory"
  echo "------------------------------------------------------"
  echo ""
}

showFailedAppNotFound(){
  echo ""
  echo "------------------------------------------------------"
  echo "Application not found $APP_DIR"
  echo "Create new application using:"
  echo "  $>./zf.sh new appname"
  echo "------------------------------------------------------"
  echo ""
}

showInvalidCmd(){
  echo ""
  echo "------------------------------------------------------"
  echo "Invalid command $CMD $APPNAME"
  echo "------------------------------------------------------"
  echo ""
}

showHelpCmd(){
  echo ""
  echo "------------------------------------------------------"
  echo "Create new web app    : ./zf.sh new appname"
  echo "Create new console app: ./zf.sh new-console appname"
  echo "Install app depedency : ./zf.sh install-deps appname"
  echo "Build app             : ./zf.sh build appname"
  echo "Run the app           : ./zf.sh run appname"
  echo "Set default app       : ./zf.sh set-default appname"
  echo "List available app    : ./zf.sh list-apps"
  echo "View default app      : ./zf.sh default-app"
  echo "Delete app            : ./zf.sh delete appname"
  echo "------------------------------------------------------"
  echo "If default app already set using set-default,"
  echo "simply call without app name"
  echo "Install app depedency : ./zf.sh install-deps"
  echo "Build app             : ./zf.sh build"
  echo "Run the app           : ./zf.sh run"
  echo "------------------------------------------------------"
  echo ""
}

showInvalidAppName(){
  echo ""
  echo "------------------------------------------------------"
  echo "$APP_DIR already exist, try another appname"
  echo "------------------------------------------------------"
  echo ""
}

showNotAllowedCmd(){
  echo ""
  echo "------------------------------------------------------"
  echo "Command not allowed"
  echo "------------------------------------------------------"
  echo ""
}

# run command
runCmd(){
  local quit=0

  while [ 1 ]
  do
    #cd $WORK_DIR
    local stopCompile=0

    if [ $quit -eq 0 ] && [ -f $JS_SRC_TO_COMPILE ]
    then
      rm -f $JS_OUT_APPNAME
      nimJsCompileCmd $JS_SRC_TO_COMPILE
      stopCompile=$?
    fi

    if [ $stopCompile -eq 0 ]
    then
      ps -ef | grep "./$APPNAME" | awk '{print $2}' | xargs kill -9 \
      && echo $APPNAME" exited." || echo $APPNAME" exited."
    fi

    if [ $quit -eq 1 ]
    then
      exit
    fi

    if [ $stopCompile -eq 0 ] && [ -f $SRC_TO_COMPILE ]
    then
      rm -f $OUT_APPNAME
      if [ $RELEASE_MODE -eq 0 ]
      then
        nimCompileCmd $SRC_TO_COMPILE
      else
        nimCompileReleaseCmd $SRC_TO_COMPILE
      fi

      stopCompile=$?

      if [ $stopCompile -eq 0 ]
      then
        if [ $BUILD -eq 0 ]
        then
          exeAppName=${SRC_TO_COMPILE##*/}
          cd $APP_DIR
          appRunCmd ${exeAppName//.nim/""} &
          cd - &>/dev/null
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

newWebProjectCmd(){
  local templateDir=".templates/web"

  if [ ! -d $APP_DIR ]
  then
    cp -r $templateDir $APP_DIR
    cp "zf.sh" $APP_DIR
    echo $APPNAME > $APP_DIR/$DEFAULT_APP
  else
    showInvalidAppName
  fi

  local sourceToCompile=$APP_SRC_DIR/"web.nim"
  local sourceJsToCompile=$APP_SRC2JS_DIR/"web.nim"

  if [ ! -d $JS_SRC_COMPILED_DIR ]
  then
    mkdir -p $JS_SRC_COMPILED_DIR
    if [ ! $? -eq 0 ]
    then
      showFailedCreateJsOutputDir
    fi
  fi

  mv $sourceToCompile $SRC_TO_COMPILE
  mv $sourceJsToCompile $JS_SRC_TO_COMPILE
  local outputCompiledJsName=${JS_OUT_APPNAME##*/}
  outputCompiledJsName=${outputCompiledJsName//".nim"/".js"}
  # run karun to create html of the js apps
  if [ -x $(which karun) ]
  then
    cd $APP_SRC2JS_DIR
    karun $JS_SRC_TO_COMPILE
    cd - &>/dev/null
    local outputCompiledJs=${JS_SRC_TO_COMPILE//".nim"/".js"}
    mv ${JS_SRC_TO_COMPILE//".nim"/".html"} $STATIC_INDEX_HTML
    local STATIC_INDEX_HTMLTmp=$STATIC_INDEX_HTML".tmp"
    sed 's|'$outputCompiledJsName'|'"/private/js/compiled/$outputCompiledJsName"'|g' $STATIC_INDEX_HTML > $STATIC_INDEX_HTMLTmp
    mv $STATIC_INDEX_HTMLTmp $STATIC_INDEX_HTML
    mv ${JS_SRC_TO_COMPILE//".nim"/".js"} $JS_SRC_COMPILED_DIR
  fi

  if [ -d $APP_DIR ]
  then
    showNewProjectHints
  else
    showFailedCreateProject
  fi
}

newConsoleProjectCmd(){
  local templateDir=".templates/console"
  if [ ! -d $APP_DIR ]
  then
    cp -r $templateDir $APP_DIR
    cp "zf.sh" $APP_DIR
    echo $APPNAME > $APP_DIR/$DEFAULT_APP
  else
    showInvalidAppName
  fi
  local sourceToCompile=$APP_SRC_DIR/"console.nim"
  mv $sourceToCompile $SRC_TO_COMPILE
  if [ -d $APP_DIR ]
  then
    showNewProjectHints
  else
    showFailedCreateProject
  fi
}

newProjectCmd(){
  # get application type on new project
  # default is web
  local appType=$1
  case $appType in
    "web")
      newWebProjectCmd
      ;;

    "console")
      newConsoleProjectCmd
      ;;
  esac
}

installDeps(){
  local depsFile=$APP_DIR/"deps"
  local depsFolder=$APP_DIR/"nimbleDeps"

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
        echo "------------------------------------------------------"

        local installedDep=`nimble list -i|grep $nimDepPkg`
        if [ "$installedDep" == "" ]
        then
          case $nimCmd in
            "install")
              echo "y" | nimble install $nimDepPkg
              ;;
            "develop")
              echo "y" | nimble develop $nimDepPkg
              ;;
          esac

        else
          echo "Dependency already exist!"
          echo $installedDep
          echo `nimble path $nimDepPkg`
        fi

        echo "------------------------------------------------------"
        echo ""
      fi
    done < $depsFile
  fi

  echo ""
  echo "------------------------------------------------------"
  echo "Looking nimbleDeps folder"
  for d in $depsFolder/*
  do
    if [ -d $d ]
    then
      echo "git pull $d"
      cd $d
      git pull
      cd $WORK_DIR
      echo ""
    fi
  done
  echo "------------------------------------------------------"
  echo ""

  cd $WORK_DIR
}

showListApps(){
    echo ""
    echo "------------------------------------------------------"
    echo "Loking for the existing applications"
    for d in $PROJECT_DIR/*
    do
      if [ -d $d ]
      then
          echo "-> ${d##*/}"
      fi
    done
    echo "------------------------------------------------------"
    echo ""
}

deleteAppCmd(){
  if [ -d $APP_DIR ]
  then
    echo ""
    echo "------------------------------------------------------"
    echo "Are you sure want to delete $APPNAME?[y/n]"
    read input
    case $input in
      "y")
        echo "delete $APP_DIR..."
        rm -rf $APP_DIR
        echo "completed."
        ;;
      *)
        echo "delete nothing."
        ;;
    esac
    echo "------------------------------------------------------"
    echo ""
  else
    showFailedAppNotFound
  fi
}

showAppConfig(){
  local appConfig="$APP_DIR/settings.json"
  echo ""
  echo "------------------------------------------------------"
  echo "Application config $appConfig"

  if [ ! -f $appConfig  ]
  then
    echo "Create new config, copy $appConfig.example -> $appConfig"
    cp "$appConfig.example" $appConfig
  fi

  cat $appConfig

  echo "------------------------------------------------------"
  echo ""
}

showDefaultApp(){
  echo ""
  echo "------------------------------------------------------"

  if [ -f "$WORK_DIR/.defaultapp" ]
  then
    echo "Default app:"
    cat "$WORK_DIR/.defaultapp"
  else
    echo "Default app not set, use command below to set default app"
    echo "  $>./zf.sh set-default appname"
  fi

  echo "------------------------------------------------------"
  echo ""
}

releaseCmd(){
  echo "release command not implemented!"
}

# verify command action
# parameter $1 is type of command ex, run:appname:...
verifyCmd(){
  # always compy the latest zf.sh
  # if not from app dir
  if [ $APP_DIR != $WORK_DIR ] && [ -d $APP_DIR ]
  then
    cp "zf.sh" $APP_DIR
  fi

  if [ -f $APPNAME"App.nim" ]
  then
    showNotAllowedCmd
    showHelpCmd
    return
  fi

  setCmdParam

  case $CMD in
    "run")
      runCmd
      ;;
    "release-run")
      # set release mode to false
      RELEASE_MODE=1
      runCmd
      ;;
    "build")
      BUILD=1
      runCmd
      ;;
    "release-build")
      RELEASE_MODE=1
      BUILD=1
      runCmd
      ;;
    "delete")
      deleteAppCmd
      ;;
    "config")
      showAppConfig
      ;;
    "new")
      newProjectCmd "web"
      ;;
    "new-console")
      newProjectCmd "console"
      ;;
    "list-apps")
      showListApps
      ;;
    "default-app")
      showDefaultApp
      ;;
    "install-deps")
      installDeps
      ;;
    "set-default")
      echo $APPNAME > $DEFAULT_APP
      ;;
    *)
      showHelpCmd
      ;;
  esac

  unsetCmdParam
}

# call main script
verifyCmd $@
