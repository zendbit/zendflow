import
  db_postgres

import
  zfcore/zendFlow

import
  dbs,
  settings

proc pgConn(): DbConn =
  if not jsonSettings.isNil():
    let pgsql = jsonSettings{"pgsql"}
    if not pgsql.isNil():
      let conn = newDbs(
        pgsql{"username"}.getStr(),
        pgsql{"password"}.getStr(),
        pgsql{"database"}.getStr(),
        pgsql{"host"}.getStr(),
        pgsql{"port"}.getInt()).tryPgSqlConn()

      if conn.success:
        result = conn.conn

      else:
        echo conn.msg
