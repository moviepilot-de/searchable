require 'rails/all'

require './lib/searchable'

module Searchable
  class Application < Rails::Application
  end
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :movies, force: true do |t|
    t.string :title
    t.string :original_title
    t.boolean :published
  end
end
