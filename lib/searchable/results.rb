module Searchable
  class Results < Array
    def initialize(items, total, page = nil, per = 20)
      @total = total
      @page = page
      @per = per

      super(items)
    end

    def current_page
      @page
    end

    def total_entries
      @total
    end

    def limit_value
      @per
    end

    def total_pages
      (@total.to_f / limit_value.to_f).ceil
    end

    def aggregations=(aggregations)
      @aggregations = aggregations
    end

    def aggregations
      @aggregations || []
    end
  end
end
