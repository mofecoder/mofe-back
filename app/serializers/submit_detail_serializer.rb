class SubmitDetailSerializer < SubmitSerializer
  attributes :source
  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read
  end
end
