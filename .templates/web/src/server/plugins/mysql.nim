import
  db_mysql

import
  zfcore/zendFlow

import
  dbs,
  settings

proc myConn*(): DbConn =
  if not jsonSettings.isNil():
    let pgsql = jsonSettings{"pgsql"}
    if not pgsql.isNil():
      let conn = newDbs(
        pgsql{"username"}.getStr(),
        pgsql{"password"}.getStr(),
        pgsql{"database"}.getStr(),
        pgsql{"host"}.getStr(),
        pgsql{"port"}.getInt()).tryMysqlConn()

      if conn.success:
        result = conn.conn

      else:
        echo conn.msg

export
  db_mysql
