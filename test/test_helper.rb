require 'bundler/setup'
require 'minitest/autorun'
require 'mocha/setup'

# Configure Rails
ENV["RAILS_ENV"] = "test"

require 'active_support'
require 'active_model'
require 'rails/engine'
require 'rails/railtie'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'responders'

I18n.enforce_available_locales = true
I18n.load_path << File.expand_path('../locales/en.yml', __FILE__)
I18n.reload!

Responders::Routes = ActionDispatch::Routing::RouteSet.new
Responders::Routes.draw do
  resources :news
  ActiveSupport::Deprecation.silence do
    get '/admin/:action', controller: 'admin/addresses'
    get '/:controller(/:action(/:id))'
  end
end

class ApplicationController < ActionController::Base
  include Responders::Routes.url_helpers

  self.view_paths = File.join(File.dirname(__FILE__), 'views')
  respond_to :html, :xml
end

class ActiveSupport::TestCase
  self.test_order = :random

  setup do
    @routes = Responders::Routes
  end
end

if ActionPack::VERSION::STRING >= '5.0.0'
  require 'rails-controller-testing'

  ActionController::TestCase.include Rails::Controller::Testing::TestProcess
  ActionController::TestCase.include Rails::Controller::Testing::TemplateAssertions
else
  # TODO: Remove this compatibility monkeypatch when we drop support for Rails 4.2.
  class ActionController::TestCase
    def post(action, options = {})
      params = options.delete(:params) || {}
      super(action, params.merge(options))
    end

    def put(action, options = {})
      params = options.delete(:params) || {}
      super(action, params.merge(options))
    end

    def delete(action, options = {})
      params = options.delete(:params) || {}
      super(action, params.merge(options))
    end

    def get(action, options = {})
      params = options.delete(:params) || {}
      super(action, params.merge(options))
    end
  end
end

module ActionDispatch
  class Flash
    class FlashHash
      def used_keys
        @discard
      end
    end
  end
end

class Model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :persisted, :updated_at
  alias :persisted? :persisted

  def persisted?
    @persisted
  end

  def to_xml(*args)
    "<xml />"
  end

  def initialize(updated_at=nil)
    @persisted = true
    self.updated_at = updated_at
  end
end

class Address < Model
end

class User < Model
end

class News < Model
end

module MyEngine
  class Business < Rails::Engine
    isolate_namespace MyEngine
    extend ActiveModel::Naming
  end
end
