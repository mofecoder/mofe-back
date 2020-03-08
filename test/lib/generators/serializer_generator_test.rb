require 'test_helper'
require 'generators/serializer/serializer_generator'

class SerializerGeneratorTest < Rails::Generators::TestCase
  tests SerializerGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
