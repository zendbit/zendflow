import
  base64,
  strutils

import
  zfcore/zendflow

proc validateBasicAuth*(httpHeaders: HttpHeaders, username: string, password: string): bool =
  let auth = ($"Authorization".getHttpHeaderValues(httpHeaders)).split(" ")
  if auth.len() == 2:
    let userPass = auth[1].decode().split(":")
    if userPass.len() == 2:
      result = userPass[0] == username and userPass[1] == password
