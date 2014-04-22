require 'spec_helper'

describe Searchable do

  class SearchableModel < ActiveRecord::Base
    include Searchable
    self.table_name = 'movies'
    attr_accessible :title, :published
  end

  class ModelWithoutOptions < SearchableModel
    searchable :title
  end

  class ModelWithCondition < SearchableModel
    searchable :title, if: :published
  end

  class ModelWithObserve < SearchableModel
    searchable observe: [:title] do
      index :alias do
        title
      end
    end
  end

  class ModelWithAutoUpdateDisabled < SearchableModel
    searchable :title, autoupdate: false
  end

  context 'on creating objects' do

    it 'should add the object to the index' do
      Searchable::Client.instance.should_receive(:index).with(hash_including(body: {title: 'The New Matrix'}))
      ModelWithoutOptions.create(title: "The New Matrix")
    end

    context 'with condition' do

      it 'should add the object to the index when condition is positive' do
        Searchable::Client.instance.should_receive(:index).with(hash_including(body: {title: 'The New Matrix'}))
        ModelWithCondition.create(title: "The New Matrix", published: true)
      end

      it 'should not add the object to the index when condition is negative' do
        Searchable::Client.instance.should_not_receive(:index)
        ModelWithCondition.create(title: "The New Matrix", published: false)
      end

    end

    context 'with alias and corresponding observe' do

      it 'should add the object to the index using the alias' do
        Searchable::Client.instance.should_receive(:index).with(hash_including(body: {alias: 'The New Matrix'}))
        ModelWithObserve.create(title: 'The New Matrix')
      end

    end

  end

  context 'on updating objects' do

    before do
      @model = ModelWithoutOptions.create(title: "The New Matrix")
    end

    it 'should update the index' do
      Searchable::Client.instance.should_receive(:index).with(hash_including(body: {title: 'The Matrix'}))
      @model.update_attribute(:title, 'The Matrix')
    end

    it 'should not update the index if something changed thats not configured as searchable' do
      Searchable::Client.instance.should_not_receive(:index)
      @model.update_attribute(:original_title, 'The Matrix')
    end

  end

  context 'on updating objects without autoupdate' do

    before do
      @model = ModelWithAutoUpdateDisabled.create(title: "The New Matrix")
    end

    it 'should not automatically update the index' do
      Searchable::Client.instance.should_not_receive(:index)
      @model.update_attribute(:title, 'The Matrix')
    end

  end

  context 'on updating objects with searchable condition' do

    before do
      @model = ModelWithCondition.create(title: "The New Matrix", published: true)
    end

    it 'should update the index if the condition does not change' do
      Searchable::Client.instance.should_receive(:index).with(hash_including(body: {title: 'The Matrix'}))
      @model.update_attribute(:title, 'The Matrix')
    end

    it 'should remove the object from the index if the condition changed' do
      Searchable::Client.instance.should_receive(:delete).with(hash_including(type: @model.class.name.underscore, id: @model.id))
      @model.update_attribute(:published, false)
    end

  end

  context 'on destroying objects' do

    before do
      @model = ModelWithoutOptions.create(title: "The New Matrix")
    end

    it 'should remove the object from the index' do
      Searchable::Client.instance.should_receive(:delete).with(hash_including(type: @model.class.name.underscore, id: @model.id))
      @model.destroy
    end

  end

end
