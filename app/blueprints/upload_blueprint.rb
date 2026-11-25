# frozen_string_literal: true

class UploadBlueprint < Blueprinter::Base
  identifier :id
  field :status
  # render と render_as_hash (to_json) で形式が変わらないよう ISO 8601 に固定する
  field :created_at, datetime_format: ->(time) { time.iso8601(3) }

  # サイズと形式は blob の値を使う
  field :filename, preload: { file_attachment: :blob } do |upload|
    upload.blob&.filename&.to_s
  end

  field :content_type, preload: { file_attachment: :blob } do |upload|
    upload.blob&.content_type
  end

  field :byte_size, preload: { file_attachment: :blob } do |upload|
    upload.blob&.byte_size
  end

  field :url, preload: { file_attachment: :blob } do |upload|
    upload.public_url
  end
end
