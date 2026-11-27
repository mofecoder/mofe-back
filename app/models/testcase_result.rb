class TestcaseResult < ApplicationRecord
  # デバッグ提出で保存する出力のストリーム（judge の src/judge/capture.rs と同じ名前）
  OUTPUT_STREAMS = %w[user_stdout user_stderr checker_stdout checker_stderr].freeze
  # 出力の保存期間（GCS の lifecycle と同じ。GCS の削除は遅れることがあるので、ここで期限を判断する）
  OUTPUT_RETENTION = 3.days

  belongs_to :submission
  belongs_to :testcase

  # outputs 列（JSON の文字列）を読んだもの。無い・壊れていれば nil
  # @return [Hash, nil] { 'prefix' => String, 'streams' => { name => { 'size', 'saved', 'truncated', 'error' } } }
  def outputs_meta
    return nil if outputs.blank?

    meta = JSON.parse(outputs)
    meta.is_a?(Hash) && meta['streams'].is_a?(Hash) ? meta : nil
  rescue JSON::ParserError
    nil
  end

  def outputs_expired?
    created_at + OUTPUT_RETENTION < Time.current
  end
end
