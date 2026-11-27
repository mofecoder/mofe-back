require 'google/cloud/storage'
require "logger"

module Utils::GoogleCloudStorageClient
  lgr = Logger.new $stderr
  lgr.level = Logger::INFO

  # Set the Google API Client logger
  Google::Apis.logger = lgr

  # 開発用: MOFE_GCS_ENDPOINT があれば、認証なしでそこ（fake-gcs-server など）につなぐ。
  # judge の worker と同じ GCS を見て、手元で提出から判定・出力の表示まで確かめるため
  @storage = if ENV['MOFE_GCS_ENDPOINT'].present?
    Google::Cloud::Storage.anonymous(endpoint: "#{ENV['MOFE_GCS_ENDPOINT'].chomp('/')}/") # gem は末尾の / が要る
  else
    Google::Cloud::Storage.new(
      project_id: Rails.application.credentials.gcs[:project_id],
      credentials: {
          type: "service_account",
          private_key_id: Rails.application.credentials.gcs[:private_key_id],
          private_key: Rails.application.credentials.gcs[:private_key],
          client_email: Rails.application.credentials.gcs[:client_email],
          client_id: Rails.application.credentials.gcs[:client_id],
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://accounts.google.com/o/oauth2/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
          client_x509_cert_url: Rails.application.credentials.gcs[:client_x509_cert_url]
      }
    )
  end
  @source_bucket = @storage.bucket('cafecoder-submit-source')
  @testcase_bucket = @storage.bucket('cafecoder-testcase')
  # デバッグ提出の出力（judge の worker が書き、3日で消える）。起動時にバケットを確かめない
  @output_bucket = @storage.bucket(ENV.fetch('MOFE_GCS_OUTPUT_BUCKET', 'mofe-judge-output'), skip_lookup: true)

  def self.upload_source(file_name, file_content)
    @source_bucket.create_file(StringIO.new(file_content), file_name)
  end

  # @return [String]
  def self.get_source(file_name)
    @source_bucket.file(file_name).download
  end

  def self.upload_input(uuid, name, input_data)
    @testcase_bucket.create_file(StringIO.new(input_data), "#{uuid}/input/#{name}")
    nil
  end

  def self.upload_output(uuid, name, output_data)
    @testcase_bucket.create_file(StringIO.new(output_data), "#{uuid}/output/#{name}")
    nil
  end

  def self.delete_testcase(uuid, name)
    @testcase_bucket.file("#{uuid}/input/#{name}").delete
    nil
  end

  # @return [String]
  def self.get_input(uuid, name)
    @testcase_bucket.file("#{uuid}/input/#{name}").download.read.force_encoding("UTF-8")
  end

  # @return [String]
  def self.get_output(uuid, name)
    @testcase_bucket.file("#{uuid}/output/#{name}").download.read.force_encoding("UTF-8")
  end

  # デバッグ提出の出力（バイトのまま）。無ければ nil
  # @return [String, nil]
  def self.get_judge_output(name)
    file = @output_bucket.file(name)
    file&.download&.string
  rescue Google::Cloud::NotFoundError
    nil
  end
end
