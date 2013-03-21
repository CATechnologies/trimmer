require 'i18n'
require 'test/spec'
require 'rack/mock'
require_relative '../lib/trimmer'

class Test::Unit::TestCase

  def setup
    I18n.backend = I18n::Backend::Simple.new
    I18n.default_locale = :en

    %w(en es).each do |locale|
      I18n.load_path << [locales_dir + "/#{locale}.yml"]
    end

    I18n.backend.class.send(:include, I18n::Backend::Fallbacks)
    # => [:ca, :es, :en]
    I18n.fallbacks.map(:ca => :es)
  end

  def teardown
    I18n.locale = nil
    I18n.default_locale = :en
    I18n.load_path = []
    I18n.available_locales = nil
    I18n.backend = nil
  end

  def translations
    I18n.backend.instance_variable_get(:@translations)
  end

  def store_translations(*args)
    data   = args.pop
    locale = args.pop || :en
    I18n.backend.store_translations(locale, data)
  end

  def locales_dir
    File.dirname(__FILE__) + '/test_data/locales'
  end

  def templates_dir
    File.dirname(__FILE__) + '/test_data/templates'
  end

  def templates_missing_t_dir
    File.dirname(__FILE__) + '/test_data/templates_missing_t'
  end

  def complex_templates_dir
    File.dirname(__FILE__) + '/test_data/complex_templates'
  end

end



