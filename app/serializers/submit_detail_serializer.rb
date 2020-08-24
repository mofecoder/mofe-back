class SubmitDetailSerializer < SubmitSerializer
  attributes :source, :testcase_results

  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read
  end

  def testcase_results
    if @instance_options[:in_contest] or true
      samples = []
      not_samples = []
      object.testcase_results_in_contest.each do |testcase_result|
        if @instance_options[:samples].include?(testcase_result.testcase_id)
          samples << testcase_result
        else
          not_samples << testcase_result
        end
      end

      CollectionSerializer.new(
          samples + not_samples,
          serializer: HiddenTestcaseResultSerializer
      )
    else
      CollectionSerializer.new(
          object.testcase_results,
          serializer: TestcaseResultSerializer
      )
    end
  end
end
