require 'rack'
require 'rack/request'
require 'json'
require 'tilt'
require 'i18n'

module Trimmer

  class Controller
    attr_accessor :templates_path, :allowed_keys

    def initialize(app, opts={})
      @app = app

      @templates_path = opts[:templates_path] || File.expand_path(File.dirname(__FILE__))
      @allowed_keys = opts[:allowed_keys] || "*"
    end

    # Handle trimmer routes
    # else call the next middleware with the environment.
    def call(env)
      request = Rack::Request.new(env)
      response = nil
      case request.path
      when /\/trimmer(\/([^\/]+))*\/translations\.([js]+)$/
        validate_locale($2) if $2 || ($2 && $2.empty?)
        response = translations($2, $3)
      when /\/trimmer\/([^\/]+)\/templates\.([js]+)$/
        validate_locale($1)
        response = templates($1, $2)
      when /\/trimmer\/([^\.|\/]+)\.([js]+)$/
        validate_locale($1)
        response = resources($1, $2)
      else
        response = @app.call(env)
      end

      response
    end

  protected

    def templates(locale, ext)
      [200, {'Content-Type' => 'text/javascript'}, templates_to_js(locale)]
    end


    def translations(locale, ext)
      [200, {'Content-Type' => 'text/javascript'}, translations_to_js(:locale => locale, :only => allowed_keys)]
    end 

    # Exports templates and translations in a single request
    def resources(locale, ext)
      opts = {:only => allowed_keys}
      opts[:locale] = locale if locale && !locale.empty?

      response = translations_to_js(opts)
      response << "\n"
      response << templates_to_js(locale)
      [200, {'Content-Type' => 'text/javascript'}, response]
    end

    #Render a template (using Tilt)
    def render_to_string(path, opts={})
      template = Thread.current[:"#{path}"] || Thread.current[:"#{path}"] = Tilt.new(path, opts)
      ::I18n.with_exception_handler(:raise_all_exceptions) do
        template.render
      end
    end

    #Validates locale is one recognised by I18n::Locale::Tag implementation
    def validate_locale(locale)
      raise "Invalid locale" unless ::I18n::Locale::Tag.tag(locale)
    end

    # Gets all templates and renders them as JSON, to be used as Mustache templates
    def templates_to_js(locale)
      ::I18n.with_locale(locale) do
        templates = JSON.dump(get_templates_from(templates_path))
        "Templates = (#{templates});"
      end
    end

    # Traverses recursively base_path and fetches templates
    def get_templates_from(base_path)
      templates = {}
      Dir.glob("#{base_path}/**").each do |entry|
        if File.directory? entry
          templates[File.basename(entry)] = get_templates_from entry
        elsif File.file? entry
          name = File.basename(entry).split('.').first
          if !name.empty?
            templates[name] = render_to_string(entry, :ugly => true)
          end
        end
      end
      templates
    end

    # Dumps all the translations. Options you can pass:
    # :locale. If specified, will dump only translations for the given locale.
    # :only. If specified, will dump only keys that match the pattern. "*.date"
    def translations_to_js(options = {})
      "if(typeof(I18n) == 'undefined') { I18n = {}; };\n" +
      "I18n.translations = (#{locale_with_fallback(options).to_json});"
    end

    def locale_with_fallback options
      original_translation = ::I18n.to_hash(options) || {}
      fallback_translation = ::I18n.to_hash(options.merge(:locale => ::I18n.default_locale))
      fallback_translation ||= {}
      fallback_translation.deep_merge original_translation
    end

  end
end
