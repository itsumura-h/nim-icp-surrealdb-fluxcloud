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

## Internet Identity と Flux バックエンドの認証設計

確認日: 2026-03-09 UTC

### 目的

このプロジェクトでは、ICP 側は Internet Identity による認証済み principal の受け取りと、外部検証可能な署名付き証明の発行に責務を限定する。通常のバックエンドアプリケーションと DB は Flux に配置し、業務 API・セッション管理・永続化は Flux 側で扱う。

責務分離は以下を前提とする。

- ICP: Internet Identity ログイン、`caller()` による principal 確認、Chain Key 署名による attestation 発行
- Flux backend: challenge 発行、ICP 署名検証、短命セッション発行、業務 API の認可
- Flux DB: principal を外部主体 ID として保存し、アプリ内部 ID と紐付ける

### 確定仕様

- Internet Identity でログインした後に dapp が取得するユーザー識別子は principal であり、`identity.getPrincipal()` で取得する
- principal の文字列表現は canonical なテキスト形式で、通常は `aaaaa-bbbbb-...` のような Base32 + ハイフン形式になる
- Internet Identity の principal は dapp の origin ごとの擬名 ID であり、protocol・hostname・port のいずれかが変わると別 principal になる
- 同一 principal を複数 origin で共有したい場合は `derivationOrigin` と `/.well-known/ii-alternative-origins` を使うが、自分で管理している origin だけを許可する
- II の delegation は frontend の session key に対して発行される。最大 30 日、既定は 30 分で、短めの有効期限が推奨される
- 認証付き canister では anonymous principal を早期 reject する
- 本番で IC 側の検証を行う実装では `fetchRootKey()` に依存しない

### 設計判断

- principal は「外部主体 ID」として使うが、それ単体では認証証明にしない
- Flux backend は principal 文字列の自己申告を信用せず、ICP 側 canister が署名した短命 attestation を検証してからアプリセッションを発行する
- Flux は trust anchor ではなく、検証済み attestation を受けて短命セッションへ変換するアプリ実行基盤として使う
- frontend のログイン起点は 1 つの canonical origin に固定する。Flux のノード直 URL、preview URL、raw URL をログイン導線に混ぜない

### 推奨フロー

1. Flux 上の frontend は `https://app.example.com` のような単一の canonical origin で配信する
2. ユーザーが Internet Identity でログインし、frontend が principal を取得する
3. Flux backend が challenge を発行する。最低でも `nonce`、`aud`、`exp`、`jti` を含め、短寿命にする
4. frontend が challenge を auth canister に送る
5. auth canister は update call の `caller()` を trusted principal として受け取り、`{ sub, aud, nonce, exp, origin, ver }` の payload に Chain Key 署名を付ける
6. frontend が署名済み attestation を Flux backend に渡す
7. Flux backend が pin 済み公開鍵で署名を検証し、`nonce` 未使用、`exp` 未超過、`aud` 一致を確認してから短命セッションを発行する
8. 以後の業務 API は Flux backend のセッション cookie で認証し、DB 上では principal との紐付けで認可する

### バックエンド実装で重視する点

- login 完了条件を `principal を受け取ったこと` ではなく `ICP 署名済み attestation を検証できたこと` に置く
- challenge は 1 回限りで失効させ、`nonce` と `jti` の再利用を防ぐ
- `aud` は Flux backend 固有値に固定し、他サービス向け証明の使い回しを防ぐ
- セッションは HttpOnly、Secure、SameSite を付けた短命 cookie を基本にする
- backend の認可判定は常に `session.sub == users.ii_principal_text` を基準にする
- principal 変更リスクの大半は origin 変更で発生するため、origin 管理を認証要件として扱う

### 非推奨

- principal 文字列だけを backend に送ってログイン完了とみなす
- identity anchor を user id として保存または利用する
- Flux の複数 URL や preview URL を混在させたまま II ログインを許可する
- anonymous principal を認証 API で許容する
- 本番検証で `fetchRootKey()` を使う

### DB モデルの最小案

- `users.id`: アプリ内部 UUID
- `users.ii_principal_text`: Internet Identity principal の canonical 文字列。`UNIQUE`
- `users.ii_derivation_origin`: 必要時のみ保持する canonical origin
- `sessions`: Flux backend が発行した短命セッションの管理
- 業務テーブルの認可: principal 直値または `users.id` を経由して判定

### 要約

最小構成は以下の分離になる。

- Internet Identity: 本人確認
- ICP auth canister: principal 確認と Chain Key 署名
- Flux backend: attestation 検証と短命セッション発行
- Flux DB: principal を主体キーとして保存し、業務データと紐付ける
