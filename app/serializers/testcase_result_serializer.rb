class TestcaseResultSerializer < ActiveModel::Serializer
  attributes :testcase_name, :status, :execution_time, :execution_memory
  attribute :score, if: :is_admin?

  def testcase_name
    object.testcase.name
  end

  def is_admin?
    @instance_options[:admin]
  end
end
