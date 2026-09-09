require 'oj'

# blueprinter は初回 Oj.dump 時に暗黙的に mimic_JSON を呼ぶため、
# 初期化タイミングを固定して JSON.parse / JSON.generate の挙動を決定的にする。
Oj::Rails.mimic_JSON

Blueprinter.configure do |config|
  config.generator = Oj
  config.sort_fields_by = :definition
  config.extensions << BlueprinterActiveRecord::Preloader.new(auto: true)
end

