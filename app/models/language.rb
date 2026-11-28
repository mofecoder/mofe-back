# frozen_string_literal: true

# 提出できる言語（config/languages.json。config/initializers/languages.rb で読み込む）。
# 各要素は key、name、mime、active、legacy、libraries、aliases（{ lang, name } の配列）、
# compile_command、run_command を持つ Hash。
#
# 新旧のジャッジを並べて動かすあいだ（S8b）は、MOFE_JUDGE_LANGUAGES で出す言語を選ぶ。
# どちらのジャッジが判定するかは submissions.lang で決まる（旧ジャッジは active な言語の
# alias の lang、新しいジャッジはそれ以外）。
# - old（既定）: 旧ジャッジの言語だけを提出できる（今の本番と同じ）。新しい言語は名前を引くために
#   active: false で残す。
# - both: 新しい言語と、旧ジャッジの言語（名前に【旧】）の両方を提出できる。
# - new: 新しい言語だけ（旧ジャッジの言語は alias として当時の名前を引くだけ）。
class Language
  MODES = %w[old both new].freeze
  DEFAULT_MODE = 'old'
  LEGACY_PREFIX = '【旧】'

  class << self
    def all
      languages = Rails.application.config.x.languages
      unless @all_for&.first.equal?(languages) && @all_for[1] == mode
        @all_for = [languages, mode, build(languages, mode)]
      end
      @all_for[2]
    end

    def mode
      Rails.application.config.x.judge_languages
    end

    # MOFE_JUDGE_LANGUAGES の値を確かめる（空なら既定）。不正なら起動を止める。
    def parse_mode(value)
      return DEFAULT_MODE if value.blank?
      return value if MODES.include?(value)

      raise ArgumentError, "MOFE_JUDGE_LANGUAGES は #{MODES.join(' / ')} のどれか（#{value.inspect}）"
    end

    # languages.json の項目から、mode に合わせた一覧を作る。並びは新しい言語 → 旧ジャッジの言語。
    def build(languages, mode)
      raise ArgumentError, "unknown mode: #{mode.inspect}" unless MODES.include?(mode)

      current = languages.map do |l|
        l.merge('legacy' => false, 'active' => l['active'] && mode != 'old').freeze
      end
      return current.freeze if mode == 'new'

      prefix = mode == 'both' ? LEGACY_PREFIX : ''
      legacy = languages.select { |l| l['active'] }.flat_map do |l|
        l['aliases'].map do |a|
          {
            'key' => a['lang'], 'name' => prefix + a['name'], 'mime' => l['mime'],
            'active' => true, 'legacy' => true, 'libraries' => '', 'aliases' => [],
            'compile_command' => nil, 'run_command' => nil,
          }.freeze
        end
      end
      (current + legacy).freeze
    end

    # key か alias（過去の submissions.lang）で引く。old と both では、旧ジャッジの言語は
    # 旧ジャッジ用の項目（key）が先に当たる。
    def find_by_lang(lang)
      return nil if lang.blank?

      all.find { |l| l['key'] == lang } ||
        all.find { |l| l['aliases'].any? { |a| a['lang'] == lang } }
    end

    # 提出で受け付けるのは active な項目の key だけ（alias と旧言語は受け付けない）
    def submittable?(lang)
      all.any? { |l| l['active'] && l['key'] == lang }
    end

    # 旧ジャッジが判定する言語の項目か（old と both のときだけある）
    def legacy?(lang)
      all.any? { |l| l['legacy'] && l['key'] == lang }
    end
  end
end
