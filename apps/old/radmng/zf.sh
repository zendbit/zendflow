#!/bin/bash

#
# ZendFlow web framework for nim language
# This framework if free to use and to modify
# License: BSD
# Author: Amru Rosyada
# Email: amru.rosyada@gmail.com
# Git: https://github.com/zendbit
#

# nim js source compile command
nimJsCompileCmd(){
  nim "js" $1
}

# nim compile command
nimCompileCmd(){
  nim "c" "-d:ssl" "--opt:none" "-d:nimDebugDlOpen" $1
}

# nim compile command
nimCompileReleaseCmd(){
  nim "c" "-d:ssl" "-d:release" $1
}

# app run command
appRunCmd(){
  ./$1
}

# check if overridecmd.sh exist
if [ -f overridecmd.sh ]
then
    source overridecmd.sh
fi

# retrieve command param
CMD=$1
APPNAME=$2

# project directory
DEFAULT_APP="defaultapp"

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

setCmdParam(){
  SOURCE_DIR=$APP_DIR

  if [ $APPNAME != "" ]
  then
    SOURCE_TO_COMPILE=$SOURCE_DIR/$APPNAME"App.nim"
    SOURCE_JS_DIR=$SOURCE_DIR"/src/tojs"
    SOURCE_JS_COMPILED_DIR=$SOURCE_DIR"/www/private/js/compiled"
    SOURCE_JS_TO_COMPILE=$SOURCE_JS_DIR/$APPNAME"Js.nim"
    STATIC_INDEX_HTML=$SOURCE_DIR"/www/index.html"
  fi

  BUILD=0
  RELEASE_MODE=0
}

unsetCmdParam(){
  unset SOURCE_DIR
  unset SOURCE_TO_COMPILE
  unset SOURCE_JS_DIR
  unset SOURCE_JS_TO_COMPILE
  unset SOURCE_JS_COMPILED_DIR
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
  echo "Project created $SOURCE_DIR"
  echo ""
  echo "- run this command to install the project depedency: "
  echo "  $>./zf.sh install-deps ${SOURCE_DIR##*/}"
  echo "------------------------------------------------------"
  echo "If you plan to modify the depedency of project you can modify the deps file"
  echo "or you can directly using nimble to download the package"
  echo "------------------------------------------------------"
  echo "- run this command to run the project: "
  echo "  $>./zf.sh run ${SOURCE_DIR##*/}"
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
  echo "Failed to create project $SOURCE_DIR"
  echo "------------------------------------------------------"
  echo ""
}

showFailedCreateJsOutputDir(){
  echo ""
  echo "------------------------------------------------------"
  echo "Failed to create $SOURCE_JS_COMPILED_DIR directory"
  echo "------------------------------------------------------"
  echo ""
}

showFailedAppNotFound(){
  echo ""
  echo "------------------------------------------------------"
  echo "Application not found $SOURCE_DIR"
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
  echo "Create new app        : ./zf.sh new appname"
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
  echo "$appDir already exist, try another appname"
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

    if [ $quit -eq 0 ]
    then
      nimJsCompileCmd $SOURCE_JS_TO_COMPILE

      stopCompile=$?

      if [ $stopCompile -eq 0 ]
      then
        for file in $SOURCE_JS_DIR/*.js
        do
          local destFile=${file//$SOURCE_JS_DIR/$SOURCE_JS_COMPILED_DIR}
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
      if [ $RELEASE_MODE -eq 0 ]
      then
        nimCompileCmd $SOURCE_TO_COMPILE
      else
        nimCompileReleaseCmd $SOURCE_TO_COMPILE
      fi

      stopCompile=$?

      if [ $stopCompile -eq 0 ]
      then
        if [ $BUILD -eq 0 ]
        then
          exeAppName=${SOURCE_TO_COMPILE##*/}
          cd $APP_DIR
          appRunCmd ${exeAppName//.nim/""} &
          cd -
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
    #local appDir=$PROJECT_DIR/$APPNAME
  local appDir=$APP_DIR
  local zfTplDir="zfTpl"
  if [ ! -d $appDir ]
  then
    cp -r $zfTplDir $appDir
    cp "zf.sh" $appDir
    echo $APPNAME > $appDir/$DEFAULT_APP
  else
    showInvalidAppName
  fi

  local sourceZfTplToCompile=$SOURCE_DIR/"zfTpl.nim"
  local sourceZfJsTplToCompile=$SOURCE_JS_DIR/"zfTpl.nim"
  if [ ! -d $SOURCE_JS_COMPILED_DIR ]
  then
    mkdir $SOURCE_JS_COMPILED_DIR
    if [ ! $? -eq 0 ]
    then
      showFailedCreateJsOutputDir
    fi
  fi
  mv $sourceZfTplToCompile $SOURCE_TO_COMPILE
  mv $sourceZfJsTplToCompile $SOURCE_JS_TO_COMPILE
  local outputCompiledJsName=${SOURCE_JS_TO_COMPILE##*/}
  outputCompiledJsName=${outputCompiledJsName//".nim"/".js"}
  local STATIC_INDEX_HTMLTmp=$STATIC_INDEX_HTML".tmp"
  sed 's/zfTpl.js/'$outputCompiledJsName'/g' $STATIC_INDEX_HTML > $STATIC_INDEX_HTMLTmp
  mv $STATIC_INDEX_HTMLTmp $STATIC_INDEX_HTML

  if [ -d $SOURCE_DIR ]
  then
    showNewProjectHints
  else
    showFailedCreateProject
  fi
}

installDeps(){
  local depsFile=$SOURCE_DIR/"deps"
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

  if [ -f "$WORK_DIR/defaultapp" ]
  then
    echo "Default app:"
    cat "$WORK_DIR/defaultapp"
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
  if [ -f $APPNAME"App.nim" ]
  then
    showNotAllowedCmd
    showHelpCmd
    return
  fi

  setCmdParam

  if [ $CMD == "new" ]
  then
    newProjectCmd
  else
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
          newProjectCmd
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
  fi

  unsetCmdParam
}

# parse command
main(){
  case $CMD in
    "run")
      verifyCmd $CMD $APPNAME
      ;;
    "release-run")
      verifyCmd "release-run" $APPNAME
      ;;
    "build")
      verifyCmd "build" $APPNAME
      ;;
    "release-build")
      verifyCmd "release-build" $APPNAME
      ;;
    "list-apps")
      verifyCmd "list-apps"
      ;;
    "delete")
      verifyCmd "delete" $APPNAME
      ;;
    "config")
      verifyCmd "config" $APPNAME
      ;;
    "new")
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
          echo $APPNAME > $appDir/$DEFAULT_APP
          verifyCmd "new" $APPNAME
        else
          showInvalidAppName
        fi
      else
        showInvalidNewCmd
      fi
      ;;
    "install-deps")
      verifyCmd "install-deps" $APPNAME
      ;;
    "set-default")
      verifyCmd "set-default" $APPNAME
      ;;
    "default-app")
      verifyCmd "default-app"
      ;;
    "release")
      verifyCmd "release" $APPNAME
      ;;
    "--help")
      showHelpCmd
      ;;
    *)
      showHelpCmd
      ;;
  esac
}

# call main script
verifyCmd $@
