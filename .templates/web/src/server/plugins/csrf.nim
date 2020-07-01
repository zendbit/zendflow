# csrf generator and manager
import
  dbs,
  db_sqlite,
  times,
  std/sha1,
  os,
  strutils

let csrfDb = "csrf.db"

var db: db_sqlite.DbConn
if db.isNil:
  db = newDbs(csrfDb).trySqLiteConn().conn

if not fileExists(csrfDb) and not db.isNil:
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS csrf (
      token TEXT NOT NULL,
      created_date DATETIME NOT NULL,
      info TEXT
    )""")
  db.close()

proc cleanInvalidCsrf*() =
  if not db.isNil:
    discard db.getRow(sql"""
      DELETE FROM csrf WHERE
        (CAST(strftime('%s', ?)  AS  integer)
        - CAST(strftime('%s', created_date)  AS  integer) > 3600)
      """, $now().utc)
    db.close()

proc genCsrf*(): string =
  if not db.isNil:
    cleanInvalidCsrf()
    let tokenSeed = now().utc.format("yyyy-MM-dd HH:mm:ss:ffffff")
    let token = $secureHash(tokenSeed)
    discard db.tryInsertId(sql"""
      INSERT INTO csrf
        (token, created_date)
        VALUES (?, ?)
      """, token, tokenSeed)
    db.close()
    result = token

proc isCsrfValid*(token: string): bool =
  if not db.isNil:
    if token.strip() != "":
      return db.getValue(sql"""SELECT token FROM csrf WHERE token = ?""", token) == token
    db.close()
    result = false

proc delCsrf*(token: string) =
  if not db.isNil:
    if token.strip() != "":
      discard db.getRow(sql"""DELETE FROM csrf WHERE token = ?""", token)
    db.close()

