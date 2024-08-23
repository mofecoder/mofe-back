class SubmissionDetailSerializer < SubmissionSerializer
  attributes :compile_error, :source, :sample_count, :testcase_results, :testcase_sets

  def source
    Utils::GoogleCloudStorageClient::get_source(object.path).read.force_encoding("UTF-8")
  end

  def sample_count
    @instance_options[:samples]&.length
  end

  def testcase_results
    completed = @instance_options[:result_count] || 0
    all = @instance_options[:testcase_count]
    if completed != all || @instance_options[:hide_results] || @instance_options[:in_contest]
      []
    else
      CollectionSerializer.new(
          object.testcase_results,
          serializer: TestcaseResultSerializer,
          admin: @instance_options[:admin]
      )
    end
  end

  def testcase_sets
    @instance_options[:testcase_sets]
  end

  class SetSerializer < ActiveModel::Serializer
    attributes :name, :score, :point, :testcases, :results

  end
end
