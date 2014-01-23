module Searchable
  extend ActiveSupport::Concern

  included do
    after_save :update_index
    after_destroy :update_index

    attr_accessor :_score
  end

  module ClassMethods

    def searchable(*attributes)
      options = attributes.pop if attributes.last.is_a?(Hash)
      @searchable ||= Hashr.new({
        attributes: Hash[attributes.map { |a| [a, a] }],
        mappings: {},
        options: options || {}
      })
      yield if block_given?

      @searchable
    end

    def reindex!
      unless Client.instance.indices.exists(index: Client.configuration[:index].name)
        Client.instance.indices.create(
          index: Client.configuration[:index].name,
          body: Client.configuration[:index].except(:name)
        )
      end

      if Client.instance.indices.exists_type(index: Client.configuration[:index].name, type: self.searchable.options.as || self.name.underscore)
        Client.instance.perform_request(:delete, "/#{Client.configuration[:index].name}/#{self.searchable.options.as || self.name.underscore}")
      end

      if @searchable.mappings.present?
        Client.instance.indices.put_mapping(
          index: Client.configuration[:index].name,
          type: self.searchable.options.as || self.name.underscore,
          body: {
            (self.searchable.options.as || self.name.underscore) => { properties: @searchable.mappings }
          }
        )
      end

      total = self.count
      progressbar = ProgressBar.create(total: total, title: self.name.underscore, format: '%t: |%B| %p%% %e')
      self.includes(self.searchable.options.includes).find_in_batches(batch_size: self.searchable.options.batch_size || 100) do |batch|
        bulk = batch.map do |item|
          next if self.searchable.options.if && (item.send(self.searchable.options.if) == false || item.send(self.searchable.options.if) == nil)
          {
            index: {
              _index: Client.configuration[:index].name,
              _type: self.searchable.options.as || self.name.underscore,
              _id: item.id,
              data: item.to_indexed_json
            }
          }
        end.compact
        Client.instance.bulk(body: bulk)
        progressbar.progress += batch.size unless progressbar.progress + batch.size > total
      end
      progressbar.finish unless progressbar.progress == total
    end

    def search(body, page = 1)
      Client.search({type: self.name.underscore, body: body}, page)
    end

    # searchable DSL

    def index(attribute, mapping = nil, &block)
      @searchable.attributes[attribute] = block || attribute
      @searchable.mappings[attribute] = mapping if mapping
    end

  end

  def update_index
    return if !destroyed? && self.class.searchable.options.has_key?(:autoupdate) && self.class.searchable.options.autoupdate == false
    return if id_changed? && self.class.searchable.options.if && (self.send(self.class.searchable.options.if) == false || self.send(self.class.searchable.options.if) == nil)

    if destroyed? || changed? && (changed.map(&:to_sym) & [self.class.searchable.attributes.keys, self.class.searchable.options.if, self.class.searchable.options.observe].compact.flatten).count > 0
      update_index!
    end
  end

  def update_index!
    if destroyed? || (self.class.searchable.options.if && (self.send(self.class.searchable.options.if) == false  || self.send(self.class.searchable.options.if) == nil))
      if Client.instance.exists(index: Client.configuration[:index].name, type: self.class.searchable.options.as || self.class.name.underscore, id: id)
        Client.instance.delete(index: Client.configuration[:index].name, type: self.class.searchable.options.as || self.class.name.underscore, id: id)
      end
    else
      Client.instance.index(
        index: Client.configuration[:index].name,
        type: self.class.searchable.options.as || self.class.name.underscore,
        id: id,
        body: to_indexed_json
      )
    end
  end

  def to_indexed_json
    hash = {}
    hash[:_boost] = self.send(self.class.searchable.options.boost) if self.class.searchable.options.boost
    self.class.searchable.attributes.each do |key, value|
      hash[key] = case value
      when Symbol
        self.send(value)
      when Proc
        self.instance_eval(&value)
      else
        value
      end
    end

    hash
  end

end
