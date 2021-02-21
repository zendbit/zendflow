import zfcore

type
  HelloWorld* = ref object

proc printHelloWorld*(self: HelloWorld): string =
  return "Hello, World!"

routes:
  # accept request with /example/123456
  # id will capture the value 12345
  get "/example/<id>":
    echo params["id"]
    Http200.respHtml(HelloWorld().printHelloWorld)
