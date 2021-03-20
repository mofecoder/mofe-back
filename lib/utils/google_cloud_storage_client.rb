require 'google/cloud/storage'
require "logger"

module Utils::GoogleCloudStorageClient
  lgr = Logger.new $stderr
  lgr.level = Logger::INFO

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
  @source_bucket = @storage.bucket('cafecoder-source')
  @testcase_bucket = @storage.bucket('cafecoder-testcase')

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
end
