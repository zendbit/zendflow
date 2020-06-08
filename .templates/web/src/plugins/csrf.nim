# csrf generator and manager
import
  db_sqlite,
  times,
  std/sha1,
  os,
  strutils

let csrfDb = "csrf.db"

if not fileExists(csrfDb):
  let db = open(csrfDb, "", "", "")
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS csrf (
      token TEXT NOT NULL,
      created_date DATETIME NOT NULL,
      info TEXT
    )""")
  db.close()

proc openCsrfDb(): DBConn =
  return open(csrfDb, "", "", "")

proc cleanInvalidCsrf*() =
  let db = openCsrfDb()
  discard db.getRow(sql"""
    DELETE FROM csrf WHERE
      (CAST(strftime('%s', ?)  AS  integer)
      - CAST(strftime('%s', created_date)  AS  integer) > 3600)
    """, $now().utc)
  db.close()

proc genCsrf*(): string =
  cleanInvalidCsrf()
  let db = openCsrfDb()
  let tokenSeed = now().utc.format("yyyy-MM-dd HH:mm:ss:ffffff")
  let token = $secureHash(tokenSeed)
  discard db.tryInsertId(sql"""
    INSERT INTO csrf
      (token, created_date)
      VALUES (?, ?)
    """, token, tokenSeed)
  db.close()
  return token

proc isCsrfValid*(token: string): bool =
  let db = openCsrfDb()
  if token.strip() != "":
    return db.getValue(sql"""SELECT token FROM csrf WHERE token = ?""", token) == token
  db.close()
  return false

proc delCsrf*(token: string) =
  let db = openCsrfDb()
  if token.strip() != "":
    discard db.getRow(sql"""DELETE FROM csrf WHERE token = ?""", token)
  db.close()