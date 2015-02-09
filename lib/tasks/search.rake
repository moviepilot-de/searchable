namespace :search do
  desc 'Do a full reindex of all searchable models.'
  task :reindex => :environment do
    index = Rails.application.config.elasticsearch['index']['name']
    Searchable::Client.instance.indices.delete(index: index) if Searchable::Client.instance.indices.exists(index: index)

    Dir[Rails.root.join('app', 'models', '*.rb')].each { |path| require path }
    ActiveRecord::Base.descendants.select { |model| model.respond_to?(:searchable) }.each do |model|
      model.reindex!
    end
  end
end
