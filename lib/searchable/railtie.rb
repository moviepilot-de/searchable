module Searchable

  class Railtie < ::Rails::Railtie

    configure do
      configuration_file = File.join('config', 'elasticsearch.yml')
      config.elasticsearch = File.exist?(configuration_file) ? YAML.load_file(configuration_file)[Rails.env] : {}
    end

    rake_tasks do
      load "tasks/search.rake"
    end

  end

end
