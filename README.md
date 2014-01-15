# Searchable

Rails integration of the official elasticsearch-ruby client.

## Installation

Add this line to your application's Gemfile:

    gem 'searchable'

And then execute:

    $ bundle

## Usage

In you models include the Searchable module.
Afterwards configure the index using the searchable method.

### basic usage

Just set the list of attributes you want to index.


    class Movie < ActiveRecord::Base
      include Searchable

      searchable :title, :production_year
    end

### advanced usage

    class Movie < ActiveRecord::Base
      include Searchable

      searchable includes: [:cast] do
        index :title
        index :production_year, type: 'integer'
        index :cast do
          cast.map(&:name)
        end
      end
    end

### configuration

...

## Contributing

1. Fork it ( http://github.com/moviepilot-de/searchable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
