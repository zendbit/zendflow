# ZendFlow
High performance asynchttpserver and web framework for nim language. This is ready for production but we need to run it under proxy :-) better using nginx

## Install Nim Lang

Follow this nim language installation and setup [Nim Language Download](https://nim-lang.org/install.html)

## Clone zendflow repo and quick start
```
git clone https://github.com/zendbit/zendflow.git
```

goto zendflow dir
```
cd zendflow
```

inside zendflow you can find zf.nims file, this file is command line to manage the zendflow project.

- Create new project
```
nim zf.nims new mysite
```

the command above will create mysite app under the projects directory "projects/mysite"

- Install project dependencies
```
nim zf.nims install mysite deps
```

- Run mysite app
```
nim zf.nims run mysite
```

the command above will run mysite app on default port 8080 and bind address 0.0.0.0,
open [http://localhost:8080](http://localhost:8080) you will be redirect to [http://localhost:8080/index.html](http://localhost:8080/index.html)
