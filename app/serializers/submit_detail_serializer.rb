class SubmitDetailSerializer < SubmitSerializer
  attributes :source, :testcase_results

  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read
  end

  def testcase_results
    CollectionSerializer.new(
        object.testcase_results,
        serializer: TestcaseResultSerializer
    )

  end
end
