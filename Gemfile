source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.1'
gem 'active_model_serializers', '~> 0.10.0'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.5'
# Use Puma as the app server
gem 'puma', '~> 8.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  gem 'debug', platforms: [:mri, :mingw, :x64_mingw]
  # 静的解析 / 脆弱性チェック (CI で実行)
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'wdm', '>= 0.1.0' if Gem.win_platform?

gem 'rack-cors', '~> 3.0'

# ログイン関連
gem 'devise', '~> 5.0'
gem 'devise_token_auth', '~> 1.2'
gem 'devise-i18n', '~> 1.16'

# Zipファイル
gem 'rubyzip', '~> 3.6'

# 論理削除
gem 'discard', '~> 2.0'

# Pagination
gem 'kaminari', '~> 1.2'

gem 'google-cloud-storage', '~> 1.55'

gem 'scenic'
gem 'scenic-mysql_adapter'

gem 'concurrent-ruby', '~> 1.3'
gem 'pundit', '~> 2.5'

# JSON Serialize
gem 'blueprinter', '~> 1.1'
gem 'oj', '~> 3.16'
gem 'blueprinter-activerecord', '~> 1.3'

# activesupport 8.1.3.1 の ActiveSupport::JSON.decode は JSON.parse に options を
# 位置引数で渡すが、json 3.0 で options が keyword 専用になったため非互換。
# rails/rails main では修正済み (2026-08-28) なので、それを含むリリースが出たら外す。
gem 'json', '~> 2.18'
