require 'rails_helper'

describe 'Locomotive Mongoid Criteria extensions' do

  let(:site)         { create(:site) }
  let(:content_type) { create(:content_type, :article, site: site) }

  def create_entry(attributes = {})
    content_type.entries.build({ title: 'Entry', _label_field_name: 'title' }.merge(attributes)).tap do |entry|
      entry.send(:set_site)
      entry.save!
    end
  end

  describe '#indexed_max' do
    it 'returns the maximum value of the field across the collection' do
      3.times { create_entry }

      expect(content_type.entries.indexed_max(:_position)).to eq(2)
    end

    it 'respects the criteria selector' do
      create_entry(visible: true)
      create_entry(visible: true)
      create_entry(visible: false)

      expect(content_type.entries.where(visible: true).indexed_max(:_position)).to eq(1)
    end

    it 'returns nil when the collection is empty' do
      expect(content_type.entries.indexed_max(:_position)).to be_nil
    end

    it 'drives add_to_list_bottom to assign the next bottom position on create' do
      entries = Array.new(3) { create_entry }

      expect(entries.map(&:_position)).to eq([0, 1, 2])
    end
  end

  describe '#each_by' do
    it 'yields every matching document exactly once, in order' do
      5.times { create_entry }

      collected = []
      content_type.entries.order_by(:_position.asc).each_by(2) { |entry| collected << entry._position }

      expect(collected).to eq([0, 1, 2, 3, 4])
    end

    it 'yields nothing for an empty criteria' do
      collected = []
      content_type.entries.each_by(2) { |entry| collected << entry }

      expect(collected).to be_empty
    end
  end

  describe '#without_sorting' do
    it 'returns a criteria with the sort option removed' do
      sorted = content_type.entries.order_by(:_position.desc)
      expect(sorted.options[:sort]).to be_present

      expect(sorted.without_sorting.options[:sort]).to be_nil
    end

    it 'does not mutate the original criteria' do
      sorted = content_type.entries.order_by(:_position.desc)

      sorted.without_sorting

      expect(sorted.options[:sort]).to be_present
    end
  end

end
