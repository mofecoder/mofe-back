# frozen_string_literal: true

require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test "config/languages.json is loaded" do
    assert_operator Language.all.size, :>, 0
    assert Language.all.frozen?
    keys = Language.all.map { |l| l['key'] }
    assert_equal keys.uniq, keys
  end

  test "find_by_lang finds a language by key or alias" do
    assert_equal 'cpp23', Language.find_by_lang('cpp23')['key']
    assert_equal 'cpp23', Language.find_by_lang('cpp23_gcc:12.2.0')['key']
    assert_equal 'python:3.11.4', Language.find_by_lang('python:3.11.4')['key']
    assert_nil Language.find_by_lang('cpp')
    assert_nil Language.find_by_lang(nil)
  end

  test "submittable? accepts only the key of an active language" do
    assert Language.submittable?('cpp23')
    assert Language.submittable?('dc')
    assert_not Language.submittable?('cpp23_gcc:12.2.0')
    assert_not Language.submittable?('python:3.11.4')
    assert_not Language.submittable?('cpp')
    assert_not Language.submittable?(nil)
  end
end
