# Decentralized Cloud Stack (Nim-ICP-FluxCloud-SurrealDB)

## 概要

このリポジトリは SurrealDB を TiKV バックエンドで動かすための Docker Compose 構成を含みます。

## Compose サービス解説

### pd（Placement Driver）

- **イメージ**: `pingcap/pd`
- **役割**: TiKV クラスタの**制御・調整役**。PingCAP の TiKV における中心コンポーネント。
- **主な仕事**:
  - TiKV ノード（tikv1 / tikv2 / tikv3）のメタデータとクラスタ状態の管理
  - データのリージョン配置・スケジューリング、レプリカ配置の決定
  - 分散トランザクション用の論理タイムスタンプ（TSO）の配布
  - クライアント・TiKV ノードからの接続受け付け（ポート 2379）
- **この構成での位置づけ**: tikv1〜tikv3 が `--pd=pd:2379` で PD に接続し、1 つの TiKV クラスタを構成。SurrealDB は `tikv://pd:2379` でこのクラスタをストレージとして利用する。

### tikv1 / tikv2 / tikv3

- **イメージ**: `pingcap/tikv`
- **役割**: 分散キーバリューストアの実データを保持するノード。各ノードが `pd:2379` の PD に接続してクラスタを形成する。
- SurrealDB の永続化先として利用される。

### surreal（SurrealDB）

- **役割**: アプリケーション向けのデータベースサーバー。
- **ストレージ**: TiKV クラスタ（`tikv://pd:2379`）。pd を経由して tikv1〜tikv3 にアクセスする。
- **ポート**: 8000（デフォルト）。認証は `SURREALDB_USER` / `SURREALDB_PASS` で指定。

### app

- **プロファイル**: `app` を有効にしたときのみ起動。
- **役割**: アプリケーションサーバー。SurrealDB に `SURREALDB_URL=http://surreal:8000` で接続する。

## 起動方法

```bash
# SurrealDB + TiKV のみ
docker compose up -d

# アプリを含める場合
docker compose --profile app up -d
```

## 環境変数（主なもの）

| 変数 | 既定値 | 説明 |
|------|--------|------|
| `SURREALDB_USER` | `user` | SurrealDB ユーザー名 |
| `SURREALDB_PASS` | `pass` | SurrealDB パスワード |
| `SURREALDB_IMAGE_TAG` | `latest` | SurrealDB イメージのタグ |
