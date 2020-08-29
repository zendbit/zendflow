# ZendFlow
Zendflow now transformed to universal tools for nim lang, the main idea is for managing nim lang application

Zendflow currently support this apps template:
- Web application template:
we are using this framework for the web apps: https://github.com/zendbit/nim.zfcore
High performance asynchttpserver and web framework for nim language. This is ready for production :-) better run under nginx proxy. **On windows system you can use WSL(Window System for Linux) or using mingw, I don't have windows machine for testing the cmd compatibilty.**

start from version 1.0.6 websocket ready

***the asynchttpserver already migrate to zfblast server*** our http server implementaion using asyncnet with openssl ready. Using zendflow need to installed openssl and the compile flag default to -d:ssl

- Console application template:
Create nim console apps

## Install Nim Lang

Follow this nim language installation and setup [Nim Language Download](https://nim-lang.org/install.html)

## Install nake, nwatchdog, karax from Nimble
```shell
nimble install nake
nimble install karax
nimble install nwatchdog
```

## dont forget to add ~/.nimble/bin in your home dir in to the sytem env
different distribution have different location, in this case I put it into ~/.profile
```shell
PATH=~/.nimble/bin:PATH
```

## Clone zendflow repo and quick start
```shell
git clone https://github.com/zendbit/zendflow.git
```

goto zendflow dir
```shell
cd zendflow
```

available nake tasks:
```
Available tasks:
new - create new app. Ex: nake new console.
default-app - get/set default app. Ex: nake default-app [appname].
debug - build debug app, Ex: nake debug [appname].
release - build release app, Ex: nake release [appname].
run - run app, ex: nake run [appname].
debug-run - build debug and then run the app. Ex: nake debug-run [appname].
release-run - build release and then run the app. Ex: nake release-run [appname].
list-apps - show available app. Ex: nake list-app
delete-app - delete app. Ex: nake delete-app appname.
install-deps - install nimble app depedencies. Ex: nake install-deps [appname].
help - show available tasks. Ex: nake help.
```

example create new web app:
```shell
nake new web mywebsite
```

example create new console app:
```shell
nake new console myconsole
```

example create new web app:
```shell
nake new web mywebsite
```

after new command you can find the generated app from the templates in the apps/[your_application_name] folder.

first open the nakefile.json

console app nakefile.json
if we want to add some depedency just put into the nimble array
```javascript
{
  "appInfo": {
    "appName": "myconsole",
    "appType": "console"
  },
  "nimble": [],
  "debug": [
    {
      "action": "cmd",
      "exe": "nim",
      "props": {
        "src": "{currentAppDir}::src::myconsole.nim",
        "out": "{currentAppDir}::myconsole"
      },
      "options": "c -d:nimDebugDlOpen -o:{out} {src}"
    }
  ],
  "release": [
    {
      "action": "cmd",
      "exe": "nim",
      "props": {
        "src": "{currentAppDir}::src::myconsole.nim",
        "out": "{currentAppDir}::{appName}"
      },
      "options": "c -d:release -o:{out} {src}"
    }
  ],
  "run": [
    {
      "action": "cmd",
      "exe": "{currentAppDir}::{appName}"
    }
  ]
}
```

for example nimble depedencies on the web app nakefile.json
the nimble package tool support install/develop directly from the git repo like go lang.
see: https://github.com/nim-lang/nimble
```javascript
"nimble": [
    "develop https://github.com/zendbit/nim.uri3",
    "develop https://github.com/zendbit/nim.zfblast",
    "develop https://github.com/zendbit/nim.zfcore",
    "develop https://github.com/zendbit/nim.zfplugs",
    "develop https://github.com/zendbit/nim.stdext",
    "install karax"
  ]
```

for updating the app depedencies and installing we can directly using the nimble tools or using this command:
```shell
nake install-deps mywebsite
```

build debug only the app:
```shell
nake debug mywebsite
```

debug and run the app:
```shell
nake debug-run mywebsite
```

release only the app:
```shell
nake release mywebsite
```

release and then run the app:
```shell
nake release-run mywebsite
```

run the app only:
```shell
nake run mywebsite
```

if we focused on the one app for development and tired to write the app name, we can set the default app:
```shell
nake default-app mywebsite
```

after we set the default app, we can directly call the nake build, build-run etc whithout defines the app appname
```shell
nake debug
nake debug-run
nake release
nake run
etc...
```

show available apps:
```shell
nake list-apps
```

delete the app:
```shell
nake delete-app appname
```
