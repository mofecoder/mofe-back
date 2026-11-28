# frozen_string_literal: true

require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  def build(mode)
    Language.build(Rails.application.config.x.languages, mode)
  end

  test "config/languages.json is loaded" do
    assert_operator Language.all.size, :>, 0
    assert Language.all.frozen?
    Language::MODES.each do |mode|
      with_judge_languages(mode) do
        keys = Language.all.map { |l| l['key'] }
        assert_equal keys.uniq, keys, mode
        assert Language.all.all?(&:frozen?), mode
      end
    end
  end

  test "the default mode is old" do
    assert_equal 'old', Language.mode
    assert_equal 'old', Language.parse_mode(nil)
    assert_equal 'old', Language.parse_mode('')
    assert_equal 'both', Language.parse_mode('both')
    assert_raises(ArgumentError) { Language.parse_mode('BOTH') }
    assert_raises(ArgumentError) { Language.parse_mode('legacy') }
  end

  test "all follows the mode" do
    assert_equal 'C++23 (g++ 12.2.0)', Language.all.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }['name']
    with_judge_languages('both') do
      assert_equal '【旧】C++23 (g++ 12.2.0)', Language.all.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }['name']
    end
    with_judge_languages('new') do
      assert_nil Language.all.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }
    end
  end

  test "old offers only the languages of the legacy judge" do
    all = build('old')
    active = all.select { |l| l['active'] }
    assert_equal 19, active.size
    assert active.all? { |l| l['legacy'] }

    cpp = all.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }
    assert_equal({
      'key' => 'cpp23_gcc:12.2.0', 'name' => 'C++23 (g++ 12.2.0)', 'mime' => 'text/x-c++src',
      'active' => true, 'legacy' => true, 'libraries' => '', 'aliases' => [],
      'compile_command' => nil, 'run_command' => nil,
    }, cpp)

    # 新しい言語は提出できないが、名前は引ける
    current = all.find { |l| l['key'] == 'cpp23' }
    assert_equal [false, false], [current['active'], current['legacy']]
  end

  test "both offers new languages first and then the legacy judge with a prefix" do
    all = build('both')
    active = all.select { |l| l['active'] }
    assert_equal 38, active.size
    assert_equal [false] * 19 + [true] * 19, active.map { |l| l['legacy'] }
    assert active.select { |l| l['legacy'] }.all? { |l| l['name'].start_with?('【旧】') }
    assert_equal 'C++23 (g++ 15.3.0)', active.first['name']
    # 旧言語（active でない）は旧ジャッジでも判定できないので、旧ジャッジの項目にしない
    assert_equal false, all.find { |l| l['key'] == 'cpp17_gcc10' }['active']
    assert_equal false, all.find { |l| l['key'] == 'cpp17_gcc10' }['legacy']
    # 新しい言語の項目はそのまま（legacy: false が付くだけ）
    cpp = all.find { |l| l['key'] == 'cpp23' }
    assert_equal Rails.application.config.x.languages.find { |l| l['key'] == 'cpp23' }.merge('legacy' => false), cpp
  end

  test "new has no items of the legacy judge" do
    all = build('new')
    assert_equal Rails.application.config.x.languages.size, all.size
    assert all.none? { |l| l['legacy'] }
    assert_equal 19, all.count { |l| l['active'] }
  end

  test "find_by_lang finds a language by key or alias" do
    with_judge_languages('new') do
      assert_equal 'cpp23', Language.find_by_lang('cpp23')['key']
      assert_equal 'cpp23', Language.find_by_lang('cpp23_gcc:12.2.0')['key']
    end
    with_judge_languages('both') do
      # 並行運用のあいだは、過去の提出も旧ジャッジの項目として表示される
      assert_equal '【旧】C++23 (g++ 12.2.0)', Language.find_by_lang('cpp23_gcc:12.2.0')['name']
    end
    assert_equal 'python:3.11.4', Language.find_by_lang('python:3.11.4')['key']
    assert_nil Language.find_by_lang('cpp')
    assert_nil Language.find_by_lang(nil)
  end

  test "submittable? accepts only the key of an active item" do
    # old（既定）: 旧ジャッジの言語だけ
    assert Language.submittable?('cpp23_gcc:12.2.0')
    assert Language.submittable?('dc:1.4.1')
    assert_not Language.submittable?('cpp23')
    assert_not Language.submittable?('python:3.11.4')

    with_judge_languages('both') do
      assert Language.submittable?('cpp23')
      assert Language.submittable?('cpp23_gcc:12.2.0')
      assert_not Language.submittable?('cpp17_gcc10')
    end

    with_judge_languages('new') do
      assert Language.submittable?('cpp23')
      assert Language.submittable?('dc')
      assert_not Language.submittable?('cpp23_gcc:12.2.0')
      assert_not Language.submittable?('python:3.11.4')
    end

    Language::MODES.each do |mode|
      with_judge_languages(mode) do
        assert_not Language.submittable?('cpp'), mode
        assert_not Language.submittable?(''), mode
        assert_not Language.submittable?(nil), mode
      end
    end
  end

  test "legacy? is true only for the items of the legacy judge" do
    assert Language.legacy?('cpp23_gcc:12.2.0')
    assert_not Language.legacy?('cpp23')
    with_judge_languages('both') { assert Language.legacy?('cpp23_gcc:12.2.0') }
    with_judge_languages('new') { assert_not Language.legacy?('cpp23_gcc:12.2.0') }
  end
end
