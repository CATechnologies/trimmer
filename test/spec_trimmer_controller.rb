require_relative 'test_helper'

context Trimmer::Controller do
  F = ::File

  def request(opts={}, &block)
    Rack::MockRequest.new(Trimmer::Controller.new(@def_app, 
                                                  :templates_path => (opts[:templates_dir] || templates_dir), 
                                                  :allowed_keys => (opts[:allowed_keys] || nil))).send(opts[:meth]||:get, opts[:path]||@def_path, opts[:headers]||{})
  end

  setup do
    # @def_disk_cache = F.join(F.dirname(__FILE__), 'response_cache_test_disk_cache')

    @def_resources_en = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"trimmer\"},\"bif\":{\"key\":\"value\"}});
Templates = ({"foo":{"bar":"<span>trimmer</span>\\n"}});
VALUE

    @def_translations_en = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"trimmer\"},\"bif\":{\"key\":\"value\"}});
VALUE

    @def_translations_en_filtered = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"trimmer\"}});
VALUE

    @def_templates_en = <<-VALUE.strip
Templates = ({"foo":{"bar":"<span>trimmer</span>\\n"}});
VALUE

    @def_complex_templates_en = <<-VALUE.strip
Templates = ({"bar":{"deportes":"ES UN BAR\\n"},"foo":{"manchu":"ES UN CHINO\\n","mar":"ES MALO\\n"}});
VALUE

    @def_resources_es = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"recortadora\"},\"bif\":{\"key\":\"valor\"}});
Templates = ({"foo":{"bar":"<span>recortadora</span>\\n"}});
VALUE

    @def_translations_es = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"recortadora\"},\"bif\":{\"key\":\"valor\"}});
VALUE

    @def_templates_es = <<-VALUE.strip
Templates = ({"foo":{"bar":"<span>recortadora</span>\\n"}});
VALUE

    @def_resources_ca = <<-VALUE.strip
if(typeof(I18n) == 'undefined') { I18n = {}; };
I18n.translations = ({\"foo\":{\"trimmer\":\"trimmer\"},\"bif\":{\"key\":\"value\"}});
Templates = ({"foo":{"bar":"<span>recortadora</span>\\n"}});
VALUE


    @def_path = '/trimmer/en.js'
    @def_value = 'hello world'
    @def_app = lambda { |env| [200, {'Content-Type' => env['CT'] || 'text/html'}, @def_value]}
  end

  teardown do
    # FileUtils.rm_rf(@def_disk_cache)
  end

  specify "should return a response for /trimmer/:locale.js" do
    request(:path=>'/trimmer/en.js').body.should.equal(@def_resources_en)
    request(:path=>'/trimmer/es.js').body.should.equal(@def_resources_es)
  end

  specify "should return a response for /trimmer/:locale/templates.js" do
    request(:path=>'/trimmer/en/templates.js').body.should.equal(@def_templates_en)
    request(:path=>'/trimmer/es/templates.js').body.should.equal(@def_templates_es)
  end

  specify "should return a response for /trimmer/:locale/translations.js" do
    request(:path=>'/trimmer/en/translations.js').body.should.equal(@def_translations_en)
    request(:path=>'/trimmer/es/translations.js').body.should.equal(@def_translations_es)
  end

  specify "should forward request to next middleware if it doesn't match path" do
    request(:path=>'/trimmer/en/translations.json').body.should.equal(@def_value)
  end

  specify "should return a response for /trimmer/:locale/templates.js if fallback found" do
    lambda {
      request(:path=>'/trimmer/ca/templates.js').body.should.equal(@def_templates_es)
    }.should.not.raise(::I18n::MissingTranslationData)
  end

  specify "should return a response for /trimmer/:locale.js if fallback found" do
    lambda {
      request(:path=>'/trimmer/ca.js').body.should.equal(@def_resources_ca)
    }.should.not.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallback found when rendering all resources" do
    lambda {
      request(:path=>'/trimmer/ca.js', :templates_dir => templates_missing_t_dir)
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallback found when rendering templates" do
    lambda {
      request(:path=>'/trimmer/ca/templates.js', :templates_dir => templates_missing_t_dir)
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallbacks when rendering all resources" do
    lambda {
      ::I18n.without_fallbacks do
        request(:path=>'/trimmer/pl.js')
      end
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallback when rendering templates" do
    lambda {
      ::I18n.without_fallbacks do
        request(:path=>'/trimmer/pl/templates.js')
      end
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallbacks and locale is invalid when rendering all resources" do
    lambda {
      ::I18n.without_fallbacks do
        request(:path=>'/trimmer/foobar.js')
      end
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should reraise i18n exceptions if no fallbacks and locale is invalid when rendering templates" do
    lambda {
      ::I18n.without_fallbacks do
        request(:path=>'/trimmer/foobar/templates.js')
      end
    }.should.raise(::I18n::MissingTranslationData)
  end

  specify "should filter translations if allowed_keys option set on Trimmer::Controller instance" do
    request(:path=>'/trimmer/en/translations.js', :allowed_keys => "*.baz").body.should.equal("if(typeof(I18n) == 'undefined') { I18n = {}; };\nI18n.translations = ({});")
    request(:path=>'/trimmer/en/translations.js', :allowed_keys => "*.foo").body.should.equal(@def_translations_en_filtered)
    request(:path=>'/trimmer/en/translations.js', :allowed_keys => ["*.foo", "*.bif"]).body.should.equal(@def_translations_en)
  end

  specify "should further filter translations if allowed_keys is passed as a parameter" do
    request(:path=>'/trimmer/en/translations.js?allowed_keys=*.foo', :allowed_keys => ["*.bif", "*.foo"]).body.should.equal(@def_translations_en_filtered)
  end

  specify "should render all translations if no locale" do
    request(:path=>'/trimmer/translations.js').body.should.equal(<<-RESP.strip)
if(typeof(I18n) == 'undefined') { I18n = {}; };\nI18n.translations = ({\"foo\":{\"trimmer\":\"trimmer\"},\"bif\":{\"key\":\"value\"},\"en\":{\"foo\":{\"trimmer\":\"trimmer\"},\"bif\":{\"key\":\"value\"}},\"es\":{\"foo\":{\"trimmer\":\"recortadora\"},\"bif\":{\"key\":\"valor\"}}});
RESP
  end

  specify "should forward request to next middleware if no local when rendering templates" do
    ::I18n.without_fallbacks do
      request(:path=>'/trimmer//templates.js').body.should.equal(@def_value)
    end
  end

  specify "should forward request to next middleware if no local when rendering resources" do
    ::I18n.without_fallbacks do
      request(:path=>'/trimmer.js').body.should.equal(@def_value)
    end
  end

  specify "should return templates in alphabetical order" do
    request(:path=>'/trimmer/en/templates.js', :templates_dir => complex_templates_dir).body.should.equal(@def_complex_templates_en)
  end
end

