# Nim-ICP-FluxCloud-SurrealDB

Internet Identity を認証基盤とし、メインバックエンドを Nim basolato（Flux Cloud）、データベースを SurrealDB v3 とする構成の検討・設計リポジトリである。

## Internet Identity（ローカル開発）

ローカルの managed ネットワークで Internet Identity が有効な場合（例: `example/ii/icp.yaml` で `ii: true`、`gateway.port` が **4943**）、ブラウザでは **http://id.ai.localhost:4943/#authorize** から II を開く。icp-cli がフレンドリー名で II を公開するときは、canister ID をホストにした URL（例: `rdmx6-jaaaa-aaaaa-aaadq-cai.localhost`）では証明検証エラーとなることがある。

ポートは、そのプロジェクトの `icp.yaml` にある `networks[].gateway.port` と一致させること。

## 設計書・プロジェクト規約

アーキテクチャ、REST API の想定、データモデル、参考文献、および達成目標・規範ルールは **`.cursor/rules/project.mdc`** にまとめている（詳細設計は同ファイルの「9. 設計書 — Nim-ICP-FluxCloud-SurrealDB」節）。
