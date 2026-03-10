## SurrealDB マイグレーション用: クエリを文字列で組み立てて HTTP POST /sql で送るだけのスクリプト。
## 秘密情報はコードに直書きせず、環境変数から読み込む（SYW-SEC-001）。
## 実行例: docker compose exec app nim c -r migrate/migrate.nim
## 前提: SURREALDB_URL, SURREALDB_USER, SURREALDB_PASS は compose または env で設定済み
## Todo スキーマ適用時: SURREALDB_NS=main, SURREALDB_DB=main のまま実行（既定値で可）。NS/DB todo_app を定義した上で USE するため。

import std/[httpclient, base64, os, strutils, asyncdispatch]

proc main {.async.} =
  let baseUrl = getEnv("SURREALDB_URL", "http://surreal:8000").strip(chars = {'/'})
  let user = getEnv("SURREALDB_USER", "user")
  let pass = getEnv("SURREALDB_PASS", "pass")
  let ns = getEnv("SURREALDB_NS", "main")
  let db = getEnv("SURREALDB_DB", "main")

  let sqlUrl = baseUrl & "/sql"
  let auth = base64.encode(user & ":" & pass)

  const QUERY = """
REMOVE TABLE todo;
DEFINE TABLE todo SCHEMAFULL;
DEFINE FIELD principal ON todo TYPE string;
DEFINE FIELD title ON todo TYPE string;
DEFINE FIELD completed ON todo TYPE bool DEFAULT false;
DEFINE FIELD created_at ON todo TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON todo TYPE option<datetime> DEFAULT NONE;
DEFINE INDEX idx_todo_principal ON TABLE todo COLUMNS principal;
"""

  var client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Surreal-NS": ns,
    "Surreal-DB": db,
    "Authorization": "Basic " & auth,
    "Content-Type": "text/plain",
  })
  let resp = await client.post(sqlUrl, QUERY.strip())
  echo "status: ", resp.status
  echo "body: ", await resp.body

when isMainModule:
  waitFor main()
