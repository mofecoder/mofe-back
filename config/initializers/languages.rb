# frozen_string_literal: true

# 言語一覧（S8）。元は judge リポジトリの languages.toml で、judge の
# `tools/sync-languages.sh <backend のパス>` が config/languages.json にコピーする。直接編集しない。
Rails.application.config.x.languages =
  JSON.parse(Rails.root.join('config/languages.json').read).map(&:freeze).freeze

# 新旧のジャッジの並行運用（S8b）で出す言語。old（既定）/ both / new。app/models/language.rb を参照。
# 不正な値なら起動しない（Language.parse_mode）。Language は autoload なので after_initialize で読む。
Rails.application.config.after_initialize do
  Rails.application.config.x.judge_languages = Language.parse_mode(ENV.fetch('MOFE_JUDGE_LANGUAGES', nil))
end
