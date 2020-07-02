#!/bin/bash

#################
# nim to js compile
# override nimJsCompileCmd
#################
# nim js source compile command

nimJsCompileCmd(){
  nim js -o:$JS_OUT_APPNAME $1
}

################
# nim compile command
# override nimCompileCmd
################
# nim compile command

nimCompileCmd(){
  nim c -d:ssl -d:nimDebugDlOpen -o:$OUT_APPNAME $1
}

nimCompileReleaseCmd(){
  nim c -d:ssl -d:release -o:$OUT_APPNAME $1
}

#################
# app run command
# override appRunCmd
#################
# app run command

appRunCmd(){
  # osx example for specified install name tool
  #if [ -d /opt/pkg/lib ] && [ -x $(which install_name_tool) ]
  #then
  #  install_name_tool -add_rpath "/opt/pkg/lib" $1
  #fi
  ./$1
}
