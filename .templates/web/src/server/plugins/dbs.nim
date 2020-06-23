import
  db_postgres,
  db_mysql,
  db_sqlite,
  strformat

import
  zfcore/zendFlow

type
  Dbs* = object
    database: string
    username: string
    password: string
    host: string
    port: int

proc newDbs*(
  database: string,
  username: string,
  password: string,
  host: string,
  port: int): Dbs =
  let instance = Dbs(
    username: username,
    database: database,
    password: password,
    host: host,
    port: port
  )

  return instance

proc tryPgSqlConn*(self: Dbs): tuple[success: bool, conn: db_postgres.DbConn, msg: string] =
    try:
      result = (
        true,
        db_postgres.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} ")),
        "OK")
    except Exception as ex:
      result = (false, nil, ex.msg)

proc tryPgSqlCheck*(self: Dbs): tuple[success: bool, msg: string] =
    try:
      let c = self.tryPgSqlConn()
      if c.success:
        c.conn.close()
      return (true, "OK")
    except Exception as ex:
      result = (false, ex.msg)

proc tryMySqlConn*(self: Dbs): tuple[success: bool, conn: db_mysql.DbConn, msg: string] =
    try:
      result = (
        true,
        db_mysql.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} ")),
        "OK")
    except Exception as ex:
      result = (false, nil, ex.msg)

proc tryMySqlCheck*(self: Dbs): tuple[success: bool, msg: string] =
    try:
      let c = self.tryMySqlConn()
      if c.success:
        c.conn.close()
      return (true, "OK")
    except Exception as ex:
      result = (false, ex.msg)

proc trySqliteConn*(self: Dbs): tuple[success: bool, conn: db_sqlite.DbConn, msg: string] =
  try:
    result = (
      true,
      db_sqlite.open(
      self.database,
      "",
      "",
      ""),
      "OK")
  except Exception as ex:
    result = (false, nil, ex.msg)

proc trySqliteCheck*(self: Dbs): tuple[success: bool, msg: string] =
    try:
      let c = self.trySqliteConn()
      if c.success:
        c.conn.close()
      return (true, "OK")
    except Exception as ex:
      result = (false, ex.msg)
