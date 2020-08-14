class SubmitDetailSerializer < SubmitSerializer
  attributes :source, :testcase_results

  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read
  end

  def testcase_results
    object.testcase_results
  end
end
