import
  db_postgres,
  db_mysql,
  db_sqlite,
  zfcore/zendFlow,
  strformat

type
  Dbs*[T] = ref object
    conn: T
    database: string
    username: string
    password: string
    host: string
    port: int

proc newDbs*[T](
  database: string,
  username: string,
  password: string,
  host: string,
  port: int): Dbs[T] =
  let instance = Dbs[T](
    username: username,
    database: database,
    password: password,
    host: host,
    port: port
  )

  return instance

proc tryPgSqlConn*(self: Dbs): bool =
    try:
      self.conn = db_postgres.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} "))
      return true
    except Exception as ex:
      echo ex.msg

proc tryPgSqlCheck*(self: Dbs): bool =
    try:
      discard self.tryPgSqlConn()
      self.conn.close()
      return true
    except Exception as ex:
      echo ex.msg

proc tryMySqlConn*(self: Dbs): bool =
    try:
      self.conn = db_mysql.open(
        "",
        self.username,
        self.password,
        (&"host={self.host} " &
        &"port={self.port} " &
        &"dbname={self.database} "))
      return true
    except Exception as ex:
      echo ex.msg

proc tryMySqlCheck*(self: Dbs): bool =
    try:
      discard self.tryMySqlConn()
      self.conn.close()
      return true
    except Exception as ex:
      echo ex.msg

proc trySqliteConn*(self: Dbs): db_sqlite.DbConn =
  return db_sqlite.open(
    self.database,
    "",
    "",
    "")

proc trySqliteCheck*(self: Dbs): bool =
    try:
      discard self.trySqliteConn()
      self.conn.close()
      return true
    except Exception as ex:
      echo ex.msg
