# MOFE Backend

## How to run

Ruby version: 4.0.2

Run this commands:
```shell script

# If not installed:
$ gem install bundler

$ bundle install
$ bundle exec rails server -b 0.0.0.0 -p 4000 -e development 
```

Access to http://localhost:4000

## Rules
ブランチ名は、 feature/#(Issue Number)

## 画像アップロード (開発環境)

問題文などに貼る画像は、本番では Cloudflare R2 に、開発環境では S3 互換の [SeaweedFS](https://github.com/seaweedfs/seaweedfs) に保存する。ブラウザが署名付き URL でストレージへ直接 PUT し、Rails は画像を中継しない。

### 起動

```shell script
$ docker compose up
```

`seaweedfs` (S3 互換ストレージ) と `storage-init` (初期化) も一緒に起動する。`storage-init` は起動のたびに次を行うので、手作業は要らない (何度実行しても同じ状態になる)。

- バケット `mofe-dev` を作成する (作成済みなら何もしない)
- CORS を設定する (`http://localhost:8000` からの PUT / GET を許可。設定は `docker/seaweedfs/cors.json`)

匿名の読み取りは `docker/seaweedfs/s3.json` の `anonymous` で許可している。アクセスキーは開発専用の固定値 (`mofe-dev-access-key` / `mofe-dev-secret-key`)。

### URL

| 用途 | URL |
|------|-----|
| S3 API (Rails とブラウザの PUT) | `http://s3.localhost:8333` |
| 画像の公開 URL | `http://s3.localhost:8333/mofe-dev/<blob の key>` |

署名付き URL には Host が含まれるため、app コンテナとホストのブラウザの両方から同じ名前で届く `s3.localhost` を使っている (コンテナ内では compose のネットワークエイリアス、ホストでは `*.localhost` がループバックに解決される)。ブラウザで `s3.localhost` が引けない場合は `/etc/hosts` に次を追加する。

```
127.0.0.1 s3.localhost
```

### API

`/v4/uploads` (writer / admin のみ)。

1. `POST /v4/uploads` に `{ upload: { filename, content_type, byte_size, checksum } }` を送る (`checksum` は MD5 の Base64)
2. 返ってきた `direct_upload.url` に、`direct_upload.headers` (`{ name, value }` の配列) を付けてファイルを PUT する
3. `POST /v4/uploads/:id/complete` で完了を通知する。サイズと形式を確かめ、申告と違えば削除して 422 を返す

制限は、PNG / JPEG / GIF / WebP、1 ファイル 5 MB、1 ユーザーあたり 30 枚/時・100 枚/日・合計 1 GB (admin は回数と容量が無制限)。

### 掃除

完了しなかったアップロードと、どこにも付いていない blob をストレージから削除する。

```shell script
$ docker compose exec app bin/rails uploads:cleanup
```
