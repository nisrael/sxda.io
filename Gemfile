# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll-theme-chirpy", "~> 7.1", ">= 7.1.1"

gem "html-proofer", "~> 5.0", group: :test

# dependencies not added by default, since ruby 3.4
gem "csv", "~> 3.0"
gem "base64"
gem "bigdecimal"

group :jekyll_plugins do
  gem 'jekyll-diagrams'
  gem 'jemoji'
end

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]
