import
  asyncnet,
  asyncdispatch,
  tables,
  strutils,
  json

type
  MkApi* = ref object
    socket: AsyncSocket
    host: string
    port: int
    username: string
    password: string
    secure: bool

const WITH_SSL* = defined(ssl) or defined(nimdoc)

proc connect*(self: MkApi): Future[void] {.async.} =
  try:
    await self.socket.connect(self.host, Port(self.port))
  except Exception as ex:
    echo ex.msg

proc close*(self: MkApi) =
  try:
    self.socket.close()
  except Exception as ex:
    echo ex.msg

proc newMkApi*(
  host: string,
  port: int,
  username:string,
  password: string,
  secure: bool = false): MkApi =

  let mkApi = MkApi(
    host: host,
    port: port,
    username: username,
    password: password,
    secure: secure
  )

  mkApi.socket = newAsyncSocket()

  return mkApi

proc writeStr(
  self: MkApi,
  str: string): Future[void] {.async.} =
  await self.socket.send(str)

proc readStr(
  self: MkApi,
  length: int): Future[string] {.async.} =
  return await self.socket.recv(length)

proc writeLen(
  self: MkApi,
  word: string): Future[void] {.async.} =
  var wLenStr = ""
  var wLen = len(word).int64
  if wLen < 0x80:
    wLenStr &= $chr(wLen)
  elif wLen < 0x4000:
    wLen = wLen or 0x8000
    wLenStr &= $chr((wLen shr 8) and 0xff)
    wLenStr &= $chr(wLen and 0xff)
  elif wLen < 0x200000:
    wLen = wLen or 0xC00000
    wLenStr &= $chr((wLen shr 16) and 0xff)
    wLenStr &= $chr((wLen shr 8) and 0xff)
    wLenStr &= $chr(wLen and 0xff)
  elif wLen < 0x10000000:
    wLen = wLen or 0xE0000000
    wLenStr &= $chr((wLen shr 24) and 0xff)
    wLenStr &= $chr((wLen shr 16) and 0xff)
    wLenStr &= $chr((wLen shr 8) and 0xff)
    wLenStr &= $chr(wLen and 0xff)
  else:
    wLenStr &= $chr(0xf0)
    wLenStr &= $chr((wLen shr 24) and 0xff)
    wLenStr &= $chr((wLen shr 16) and 0xff)
    wLenStr &= $chr((wLen shr 8) and 0xff)
    wLenStr &= $chr(wLen and 0xff)

  await self.writeStr(wLenStr)

proc readLen(self: MkApi): Future[int] {.async.} =
  var length = ord((await self.readStr(1))[0])
  if (length and 0x80) == 0x00:
    return length
  if (length and 0xC0) == 0x80:
    length = length and (not 0xC0)
    length = length shl 8
    length += ord((await self.readStr(1))[0])
  elif (length and 0xE0) == 0xC0:
    length = length and (not 0xE0)
    length = length shl 8
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])
  elif (length and 0xF0) == 0xE0:
    length = length and (not 0xF0)
    length = length shl 8
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])
  elif (length and 0xF8) == 0xF0:
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])
    length = length shl 8
    length += ord((await self.readStr(1))[0])

  return length

proc writeWord(
  self: MkApi,
  word: string): Future[void] {.async.} =
  #echo "<<< " & word
  await self.writeLen(word)
  await self.writeStr(word)

proc readWord(self: MkApi): Future[string] {.async.} =
  let word = await self.readStr(await self.readLen())
  #echo ">>> " & word
  return word

proc writeSentence*(
  self: MkApi,
  words: seq[string]): Future[int] {.async.} =
  var count = 0
  for word in words:
    await self.writeWord(word)
    count += 1
  await self.writeWord("")
  return count

proc readSentence*(self: MkApi): Future[seq[string]] {.async.} =
  var sentence: seq[string] = @[]
  while true:
    let word = await self.readWord()
    if word == "":
      return sentence
    sentence.add(word)

proc talk*(
  self: MkApi,
  words: seq[string]): Future[seq[tuple[reply: string, attr: Table[string, string]]]] {.async.} =
  if (await self.writeSentence(words)) == 0:
    return
  var replySentence: seq[tuple[reply: string, attr: Table[string, string]]] = @[]
  while true:
    let sentence = await self.readSentence()
    if len(sentence) == 0:
      continue
    let reply = sentence[0]
    var attr = initTable[string, string]()
    for word in sentence[1..high(sentence)]:
      let attrKV = word[1..high(word)].split("=")
      attr[attrKV[0]] = attrKV[1]
    replySentence.add((reply, attr))
    if reply == "!done":
      return replySentence


proc login(self: MkApi): Future[bool] {.async.} =
  let words = @[
    "/login",
    "=name=" & self.username,
    "=password=" & self.password
  ]
  for mkResp in (await self.talk(words)):
    if mkResp.reply == "!trap":
      return false
  return true

proc `%`*(talkResp: tuple[reply: string, attr: Table[string, string]]): JsonNode =
  let tmp = %*{}
  tmp["reply"] = %(talkResp.reply)
  tmp["attr"] = %(talkResp.attr)
  return tmp

proc `%`*(talkResp: seq[tuple[reply: string, attr: Table[string, string]]]): JsonNode =
  let tmp = newJArray()
  for res in talkResp:
    tmp.add(%res)
  return tmp

let mkApi = newMkApi(
  "43.225.65.210",
  8728,
  "david",
  "qwerty123#"
)

waitfor mkApi.connect()
if waitfor mkApi.login():
  echo (%(waitfor mkApi.talk(@["/user/getall"]))).pretty
mkApi.close()
