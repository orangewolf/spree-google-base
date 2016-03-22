source 'http://rubygems.org'


#if RUBY_VERSION < "1.9"
#  gem "ruby-debug"
#else
#  gem "ruby-debug19"
#end

gemspec

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
#  gem 'asset_sync'
#  gem 'yui-compressor'
end

gem 'spree', '~> 3.0.0'
gem 'spree_auth_devise', git: 'git://github.com/spree/spree_auth_devise.git', branch: '3-0-stable'
# gem 'spree_multi_domain', :git => 'git://github.com/spree/spree-multi-domain.git'

group :test do
  gem 'database_cleaner'
  gem 'minitest'
end
