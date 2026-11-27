class SubmissionSerializer < ActiveModel::Serializer
  attributes :id, :user, :task, :status, :point, :public,
             :execution_time, :execution_memory, :lang, :timestamp, :judge_status, :debug

  def user
    {
        name: object.user.name
    }
  end

  def task
    ContestTaskSerializer::new(
        object.problem
    )
  end

  # デバッグ提出か（各テストケースの出力を保存する提出。S7b）
  def debug
    object.output_capture == 'all'
  end

  def timestamp
    object.created_at
  end

  def status
    object.status == 'WIP' ? 'WJ' : object.status
  end

  def judge_status
    completed = @instance_options[:result_count] || 0
    all = @instance_options[:testcase_count]
    if all.nil? || completed >= all || (completed == 0 && object.status != 'WIP')
      nil
    else
      { completed: completed + 1, all: all }
    end
  end
end
