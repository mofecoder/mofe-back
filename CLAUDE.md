# MOFE Backend

競技プログラミングプラットフォーム MOFE のバックエンド API。Rails 8.1 (API-only モード)、Ruby 4.0.6、MySQL 8.0 で構築している。

## 開発環境

開発には **Docker Compose** を使う。すべてのコマンド (rails, bundle, rake など) は**必ず** app コンテナ内で実行すること:

```sh
docker compose exec app <command>
```

### 環境の起動

```sh
docker compose up --build    # すべてのサービスをビルドして起動
docker compose up            # サービスを起動 (再ビルドなし)
docker compose down          # コンテナを停止して削除
```

### サービス

| サービス | イメージ    | ポート |
|----------|-------------|--------|
| app      | Ruby 4.0.6  | 3000   |
| db       | MySQL 8.0   | 3306   |

開発用 DB のデフォルト認証情報は `root` / `password`。ホストは `db` (Docker ネットワーク内) または `127.0.0.1` (ホストから)。

### gem の変更

`compose.yaml` はプロジェクトディレクトリ (`.:/app`) しかマウントしていない。**`/usr/local/bundle` 用のボリュームはない**ため、起動中のコンテナ内で `bundle install` した gem はそのコンテナの書き込み可能レイヤーにしか存在せず、コンテナが再作成される (設定変更後の `docker compose up`、`docker compose down` など) と消える。gem はビルド時に `Dockerfile` 内の `bundle install` でインストールされる。

`Gemfile` または `Gemfile.lock` を編集したら、イメージを再ビルドする:

```sh
docker compose build app     # 新しい gem で app イメージを再ビルド
docker compose up -d app     # そのイメージからコンテナを再作成
```

`docker compose exec app bundle install` だけを実行すると、コンテナが再作成されるまでは動いているように見えるが、再作成後に `Could not find <gem> in locally installed gems (Bundler::GemNotFound)` で起動に失敗する。

## よく使うコマンド

以下のコマンドはすべて `docker compose exec app` を前に付けて実行する。

### データベース

```sh
bundle exec rails db:create      # データベースを作成
bundle exec rails db:migrate     # 未適用のマイグレーションを実行
bundle exec rails db:seed        # シードデータを投入
bundle exec rails db:reset       # drop → create → migrate → seed
```

### テスト

Minitest (Rails デフォルト) を使う。fixture は `test/fixtures/` にある。

```sh
bundle exec rails test                         # 全テストを実行
bundle exec rails test test/models             # モデルのテストのみ
bundle exec rails test test/controllers        # コントローラのテストのみ
bundle exec rails test test/path/to/file.rb    # 特定のテストファイルを実行
bundle exec rails test test/path/to/file.rb:42 # 行番号を指定して特定のテストを実行
```

### その他

```sh
bundle exec rails routes    # 全ルートを一覧表示
bundle exec rails console   # Rails コンソールを開く
bundle install              # gem の依存関係をインストール
```

## Git ブランチ命名

- メインブランチ: `master`
- feature ブランチ: `feature/#<issue番号>`

## アーキテクチャと規約

### API バージョニング

API には 2 つの名前空間がある:

- **`/api/`** (v1、レガシー) — JSON シリアライズに `ActiveModelSerializers` を使う。認可はコントローラ内で手動で行う。
- **`/v4/`** (現行) — シリアライズに `Blueprinter`、認可に `Pundit` を使う。**新しい API エンドポイントは v4 のパターンに従うこと。**

### 認証

Devise Token Auth。認証にはトークンヘッダー (`access-token`, `uid`, `client`, `expiry`) を使う。ベースコントローラは `DeviseTokenAuth::Concerns::SetUserByToken` を include している。

- `authenticate_user!` — ログインを要求する
- `authenticate_admin_user!` — admin ロールを要求する
- `current_user` — ログイン中の `User` を返す (`current_api_user` に委譲)

### 認可 (Pundit)

v4 コントローラで使う。`V4::ApplicationController` が `Pundit::Authorization` を include し、`after_action :verify_authorized` を呼んでいる。

- ポリシーは `app/policies/` に置く
- `ApplicationPolicy` はすべてのアクションをデフォルトで `false` にする (デフォルト拒否)
- 各ポリシーは `index?`, `show?`, `create?`, `update?`, `destroy?` と `Scope` クラスを定義する

### シリアライズ (Blueprinter)

v4 コントローラで使う。blueprint は `app/blueprints/` に置く。

- レスポンスの形ごとに `view` ブロックを定義する (例: `:problem`, `:problem_detail`)
- view の合成には `include_view` を使う
- ネストしたリソースには `association` を使う
- eager loading を指定するには field / association の `preload` オプションを使う

### 論理削除 (Discard)

すべてのモデルは `ApplicationRecord` 経由で `Discard::Model` を継承している。論理削除されたレコードは `deleted_at` カラムが非 null で、デフォルトスコープ (`kept`) から除外される。

- 論理削除には `record.discard` を使う (`record.destroy` は使わない)
- 復元には `record.undiscard` を使う
- 論理削除済みレコードも含めて検索するには `Model.with_discarded` を使う

### ユーザーロール

ユーザーのロールは enum で `:member`, `:writer`, `:admin` の 3 種類。

## 主なディレクトリ構成

```
app/
├── blueprints/         # Blueprinter シリアライザ (v4)
├── controllers/
│   ├── api/            # v1 API コントローラ (レガシー)
│   └── v4/             # v4 API コントローラ (新規コードはこちら)
├── models/             # ActiveRecord モデル
├── policies/           # Pundit 認可ポリシー
├── serializers/        # ActiveModelSerializers (レガシー、v1)
└── services/           # サービスオブジェクト
test/
├── controllers/        # コントローラのテスト
├── models/             # モデルのテスト
├── policies/           # ポリシーのテスト
└── fixtures/           # テスト用 fixture (YAML)
```
