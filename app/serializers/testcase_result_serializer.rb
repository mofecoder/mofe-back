class TestcaseResultSerializer < HiddenTestcaseResultSerializer
  def testcase_name
    object.testcase.name
  end
end
