import
  db_postgres,
  db_mysql,
  db_sqlite,
  zfcore/zendFlow,
  strformat

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

proc tryPgSqlConn*(self: Dbs): tuple[success: bool, conn: db_postgres.DbConn] =
    try:
      result = (
        true,
        db_postgres.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} ")))
    except Exception as ex:
      echo ex.msg

proc tryPgSqlCheck*(self: Dbs): bool =
    try:
      let c = self.tryPgSqlConn()
      if c.success:
        c.conn.close()
      return true
    except Exception as ex:
      echo ex.msg

proc tryMySqlConn*(self: Dbs): tuple[success: bool, conn: db_mysql.DbConn] =
    try:
      result = (
        true,
        db_mysql.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} ")))
    except Exception as ex:
      echo ex.msg

proc tryMySqlCheck*(self: Dbs): bool =
    try:
      let c = self.tryMySqlConn()
      if c.success:
        c.conn.close()
      return true
    except Exception as ex:
      echo ex.msg

proc trySqliteConn*(self: Dbs): tuple[success: bool, conn: db_sqlite.DbConn] =
  try:
    result = (
      true,
      db_sqlite.open(
      self.database,
      "",
      "",
      ""))
  except Exception as ex:
    echo ex.msg

proc trySqliteCheck*(self: Dbs): bool =
    try:
      let c = self.trySqliteConn()
      if c.success:
        c.conn.close()
      return true
    except Exception as ex:
      echo ex.msg
