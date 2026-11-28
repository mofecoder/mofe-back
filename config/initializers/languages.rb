# frozen_string_literal: true

# 言語一覧（S8）。元は judge リポジトリの languages.toml で、judge の
# `tools/sync-languages.sh <backend のパス>` が config/languages.json にコピーする。直接編集しない。
Rails.application.config.x.languages =
  JSON.parse(Rails.root.join('config/languages.json').read).map(&:freeze).freeze
