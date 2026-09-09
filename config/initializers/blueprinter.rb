require 'oj'

Blueprinter.configure do |config|
  config.generator = Oj
  config.sort_fields_by = :definition
  config.extensions << BlueprinterActiveRecord::Preloader.new(auto: true)
end

