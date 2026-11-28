# frozen_string_literal: true

# MOFE_JUDGE_LANGUAGES（新旧のジャッジの並行運用、S8b）をブロックのあいだだけ切り替える。
# テストは既定の old で動く。
module JudgeLanguagesHelper
  def with_judge_languages(mode)
    x = Rails.application.config.x
    original = x.judge_languages
    x.judge_languages = mode
    yield
  ensure
    x.judge_languages = original
  end
end
