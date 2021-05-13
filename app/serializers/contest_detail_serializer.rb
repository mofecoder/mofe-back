class ContestDetailSerializer < ContestSerializer
  attributes :description, :penalty_time, :tasks, :is_writer_or_tester, :registered, :editorial

  def tasks
    return nil unless @instance_options[:include_tasks]
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: ContestTaskSerializer
    )
  end

  def is_writer_or_tester
    object.is_writer_or_tester(@instance_options[:user])
  end

  def registered
    @instance_options[:registered] || false
  end

  def editorial
    if @instance_options[:show_editorial]
      object.editorial_url
    else
      nil
    end
  end
end
