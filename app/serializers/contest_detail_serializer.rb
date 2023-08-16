class ContestDetailSerializer < ContestSerializer
  attributes :description, :penalty_time, :tasks, :is_writer_or_tester, :registered, :editorial, :written_tasks, :is_admin, :standings_mode

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

  def is_admin
    return false if @instance_options[:user].nil?
    return true if @instance_options[:user].admin?
    @instance_options[:user].admin_for_contest?(object.id)
  end
end
