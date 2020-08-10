class SubmitDetailSerializer < SubmitSerializer
  attributes :source
  def source
    File.open(object.path).read
  end
end
