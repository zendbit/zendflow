#!/bin/bash

################
# nim compile command
# override nimCompileCmd
################
# nim compile command

nimCompileCmd(){
  nim "c" "-d:nimDebugDlOpen" $1
}

nimCompileReleaseCmd(){
  nim "c" "-d:release" $1
}

#################
# app run command
# override appRunCmd
#################
# app run command

appRunCmd(){
  ./$1
}
