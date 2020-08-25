require 'google/cloud/storage'
require "logger"

module Utils::GoogleCloudStorageClient
  lgr = Logger.new $stderr
  lgr.level = Logger::WARN

  # Set the Google API Client logger
  Google::Apis.logger = lgr

  @storage = Google::Cloud::Storage.new(
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
  @bucket = @storage.bucket('cafecoder-submit-source')

  def self.upload_source(file_name, file_content)
    @bucket.create_file(StringIO.new(file_content), file_name)
  end

  def self.get_source(file_name)
    @bucket.file(file_name).download
  end
end
