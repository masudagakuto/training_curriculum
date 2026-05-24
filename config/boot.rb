ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Ruby 3.x と Rails 6.0 の互換性パッチ
# Ruby 3.x では Logger が自動的に読み込まれなくなったため明示的に require する
require 'logger'

# Ruby 3.1+ / Psych 4.x 互換パッチ
# Psych 4.0 からYAMLエイリアスがデフォルト無効になったため有効化する
require 'psych'
if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('4.0.0')
  module YAML
    class << self
      alias_method :_orig_load, :load
      def load(yaml, **opts)
        _orig_load(yaml, aliases: true, **opts)
      end
    end
  end
end
