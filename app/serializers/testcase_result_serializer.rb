class TestcaseResultSerializer < ActiveModel::Serializer
  attributes :id, :testcase_name, :status, :execution_time, :execution_memory
  attribute :score, if: :is_admin?
  # デバッグ提出の出力（S7b）。見られるストリームがある人にだけ出す
  attribute :outputs, if: :show_outputs?

  def testcase_name
    object.testcase.name
  end

  def is_admin?
    @instance_options[:admin]
  end

  def show_outputs?
    @instance_options[:output_streams].present?
  end

  # 保存していなければ nil。streams は見られるものだけを TestcaseResult::OUTPUT_STREAMS の順に並べる
  # （ストリーム名を値に入れるのは、frontend がキーを camelCase に変えるため）
  def outputs
    meta = object.outputs_meta
    return nil if meta.nil?

    allowed = @instance_options[:output_streams]
    streams = TestcaseResult::OUTPUT_STREAMS.filter_map do |name|
      info = meta['streams'][name]
      next if info.nil? || !allowed.include?(name)

      {
        stream: name,
        size: info['size'],
        saved: info['saved'],
        truncated: info['truncated'] == true,
        error: info['error'],
      }
    end
    { expired: object.outputs_expired?, streams: streams }
  end
end
