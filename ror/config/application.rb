require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Global properties for the rails app
#
# @author Eric Fehr (eric.fehr@publicis-modem.fr, github: ricofehr)
module Mvmc
  class Application < Rails::Application
    # Include externals custom apis
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Set embed property for serializers objects
    ActiveModel::Serializer.setup do |config|
       config.embed = :ids
    end

    # disable sql logging
    ActiveRecord::Base.logger = nil
  end
end
