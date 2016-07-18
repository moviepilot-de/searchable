module Searchable
  class Client
    def self.configuration
      @configuration ||= Hashr.new(Rails.application.config.elasticsearch, {
        index: {
          name: Rails.application.class.parent_name.underscore
        }
      })
    end

    def self.instance
      @client ||= Elasticsearch::Client.new({
        hosts: configuration.hosts,
        retry_on_failure: true,
        reload_connections: true
      })
    end

    def self.search(arguments, page = 1)
      response = instance.search({index: configuration['index'].name}.merge(arguments))

      records = {}
      response['hits']['hits'].group_by { |hit| hit['_type'] }.each do |type, items|
        records[type] = type.classify.constantize.where(id: items.map { |hit| hit['_id'] })
      end
      items = response['hits']['hits'].map do |hit|
        item = records[hit['_type']].detect { |record| record.id.to_s == hit['_id'] }
        item._score = hit['_score'] if item
        item
      end.compact

      results = Results.new(items, response['hits']['total'], page, arguments[:body][:size])
      if response['aggregations'].present?
        results.aggregations = Hash[response['aggregations'].map { |key, facet| [key, Hash[ facet['buckets'].map { |term| [term['key'], term['doc_count']] }] ] }]
      end

      results
    end
  end
end
