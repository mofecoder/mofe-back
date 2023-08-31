class TestcaseResultSerializer < HiddenTestcaseResultSerializer
  attributes :testcase_name, :status, :execution_time, :execution_memory
  def testcase_name
    object.testcase.name
  end
end
