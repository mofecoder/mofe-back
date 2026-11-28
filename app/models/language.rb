# frozen_string_literal: true

# 提出できる言語（config/languages.json。config/initializers/languages.rb で読み込む）。
# 各要素は key、name、mime、active、libraries、aliases（{ lang, name } の配列）、
# compile_command、run_command を持つ Hash。
class Language
  class << self
    def all
      Rails.application.config.x.languages
    end

    # key か alias（過去の submissions.lang）で引く
    def find_by_lang(lang)
      return nil if lang.blank?

      all.find { |l| l['key'] == lang } ||
        all.find { |l| l['aliases'].any? { |a| a['lang'] == lang } }
    end

    # 提出で受け付けるのは active な言語の key だけ（alias と旧言語は受け付けない）
    def submittable?(lang)
      all.any? { |l| l['active'] && l['key'] == lang }
    end
  end
end
