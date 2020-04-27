type
  HelloWorld* = ref object

proc printHelloWorld*(self: HelloWorld): string =
  return "Hello, World!"
