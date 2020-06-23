# ZendFlow
Zendflow now transformed to universal tools for nim lang, the main idea is for managing nim lang application

Zendflow currently support this apps template:
- Web application template:
we are using this framework for the web apps: https://github.com/zendbit/nim.zfcore
High performance asynchttpserver and web framework for nim language. This is ready for production :-) better run under nginx proxy. **for this release not supported windows, need to changes the zf.nims shell cmd to support windows system**

start from version 1.0.6 websocket ready

***the asynchttpserver already migrate to zfblast server*** our http server implementaion using asyncnet with openssl ready. Using zendflow need to installed openssl and the compile flag default to -d:ssl

- Console application template:
Create nim console apps

## Install Nim Lang

Follow this nim language installation and setup [Nim Language Download](https://nim-lang.org/install.html)

## Install nake from Nimble
```
nimble install nake
```

## Clone zendflow repo and quick start
```
git clone https://github.com/zendbit/zendflow.git
```

goto zendflow dir
```
cd zendflow
```

available nake tasks:
```
Available tasks:
new - create new app. Ex: nake new console.
default-app - get/set default app. Ex: nake default-app [appname].
build - build app, Ex: nake build [appname].
release - release app, Ex: nake release [appname].
run - run app, ex: nake run [appname].
build-run - build and then run the app. Ex: nake build-run [appname].
release-run - release and then run the app. Ex: nake release-run [appname].
list-apps - show available app. Ex: nake list-app
delete-app - delete app. Ex: nake delete-app appname.
install-deps - install nimble app depedencies. Ex: nake install-deps [appname].
help - show available tasks. Ex: nake help.
```

example create new web app:
```
nake new web mywebsite
```

example create new console app:
```
nake new console myconsole
```

after new command you can find the generated app from the templates in the apps/[your_application_name] folder.

build only the app:
```
nake build mywebsite
```

build and run the app:
```
nake build-run mywebsite
```

release only the app:
```
nake release mywebsite
```

release and then run the app:
```
nake release-run mywebsite
```

run the app only:
```
nake run mywebsite
```

if we focused on the one app for development and tired to write the app name, we can set the default app:
```
nake default-app mywebsite
```

after we set the default app, we can directly call the nake build, build-run etc whithout defines the app appname
```
nake build
nake build-run
nake release
nake run
etc...
```

show available apps:
```
nake list-apps
```

delete the app:
```
nake delete-app appname
```

define app depedencies for distribution and deployment
lets open the "nakefile.json", we can modify the nimble array as we need. We can define install or develop mode when add to the depedencies
```
{
  "appInfo": {
    "appName": "test",
    "appType": "console"
  },
  "nimble": [
    "install url3",
    "install gatabase",
    "develop zfcore"
    etc...
  ]
}
```

after we configured the depedencies, we can run install-deps command
```
nake install-deps appname
```

or if we already set the default app, we can just call
```
nake install-deps
```
