module Searchable

  class Railtie < ::Rails::Railtie

    configure do
      configuration_file = File.join('config', 'elasticsearch.yml')
      config.elasticsearch = YAML.load_file(configuration_file)[Rails.env] if File.exist?(configuration_file)
    end

    rake_tasks do
      load "tasks/search.rake"
    end

  end

end
