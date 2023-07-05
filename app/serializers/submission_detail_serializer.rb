class SubmissionDetailSerializer < SubmissionSerializer
  attributes :compile_error, :source, :sample_count, :testcase_results

  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read.force_encoding("UTF-8")
  end

  def sample_count
    @instance_options[:samples]&.length
  end

  def testcase_results
    completed = @instance_options[:result_count] || 0
    all = @instance_options[:testcase_count]
    if completed != all || @instance_options[:hide_results]
      []
    elsif @instance_options[:in_contest]
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
