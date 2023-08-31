class HiddenTestcaseResultSerializer < ActiveModel::Serializer
  attributes :testcase_name, :status, :execution_time, :execution_memory

  def testcase_name
    nil
  end
end
