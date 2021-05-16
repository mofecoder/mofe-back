class ContestDetailSerializer < ContestSerializer
  attributes :description, :penalty_time, :tasks, :is_writer_or_tester, :registered, :editorial, :written_tasks

  def tasks
    return nil if @instance_options[:include_tasks].nil?
    ActiveModel::Serializer::CollectionSerializer.new(
        @instance_options[:include_tasks],
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

  def written_tasks
    @instance_options[:written]
  end
end
