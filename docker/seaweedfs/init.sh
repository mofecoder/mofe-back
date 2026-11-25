#!/bin/sh
# 開発用 SeaweedFS の初期化 (compose の storage-init サービスから実行される)
# バケットの作成と CORS の設定を行う。何度実行しても同じ状態になる。
# 匿名の読み取りは s3.json の anonymous identity で許可している。
set -eu

BUCKET="${BUCKET:-mofe-dev}"

# S3 ゲートウェイが応答するまで待つ
i=0
until aws s3api list-buckets > /dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "SeaweedFS の S3 ゲートウェイに接続できません: $AWS_ENDPOINT_URL" >&2
    exit 1
  fi
  sleep 1
done

if aws s3api head-bucket --bucket "$BUCKET" > /dev/null 2>&1; then
  echo "バケット $BUCKET は作成済み"
else
  aws s3api create-bucket --bucket "$BUCKET"
  echo "バケット $BUCKET を作成しました"
fi

aws s3api put-bucket-cors --bucket "$BUCKET" --cors-configuration file:///init/cors.json
echo "バケット $BUCKET に CORS を設定しました"
