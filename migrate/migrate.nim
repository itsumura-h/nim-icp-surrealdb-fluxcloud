## SurrealDB マイグレーション用: クエリを文字列で組み立てて HTTP POST /sql で送るだけのスクリプト。
## 秘密情報はコードに直書きせず、環境変数から読み込む（SYW-SEC-001）。
## 実行例: docker compose exec app nim c -r migrate/migrate.nim
## 前提: SURREALDB_URL, SURREALDB_USER, SURREALDB_PASS は compose または env で設定済み

import std/[httpclient, base64, os, strutils, asyncdispatch]

proc main {.async.} =
  let baseUrl = getEnv("SURREALDB_URL", "http://surreal:8000").strip(chars = {'/'})
  let user = getEnv("SURREALDB_USER", "user")
  let pass = getEnv("SURREALDB_PASS", "pass")
  let ns = getEnv("SURREALDB_NS", "main")
  let db = getEnv("SURREALDB_DB", "main")

  let sqlUrl = baseUrl & "/sql"
  let auth = base64.encode(user & ":" & pass)

  # クエリを文字列で組み立ててそのまま送る（引数があれば第1引数、なければ例として INFO FOR DB）
  let query = if paramCount() > 0: paramStr(1) else: "INFO FOR DB;"

  var client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Surreal-NS": ns,
    "Surreal-DB": db,
    "Authorization": "Basic " & auth,
    "Content-Type": "text/plain",
  })
  let resp = await client.post(sqlUrl, query)
  echo "status: ", resp.status
  echo "body: ", await resp.body

when isMainModule:
  waitFor main()
