# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../channels/sport_tvp_pl'

RSpec.describe Channels::SportTvpPl do
  before { Tables::SeenItems.setup! }

  describe '.rss', :vcr do
    subject(:rss) { VCR.use_cassette('sport_tvp_pl_rss') { described_class.rss } }

    let(:source_xml) { VCR.use_cassette('sport_tvp_pl_rss') { Faraday.get(described_class::RSS_URL).body } }
    let(:source_items) { source_xml.scan(%r{<item>.*?</item>}m) }
    let(:source_items_by_id) { source_items.group_by { |item| item[described_class::ITEM_ID_PATTERN, 1] } }
    let(:source_item_ids) { source_items_by_id.keys }
    let(:source_duplicate_items) do
      source_items_by_id.values.select { |items_with_same_id| items_with_same_id.size > 1 }.map do |items|
        items.min_by { |item| Time.parse(item[%r{<pubDate>(.*?)</pubDate>}, 1]).to_i }
      end
    end
    let(:kept_items) { source_items - source_duplicate_items - source_items_by_id.values_at(*seen_item_ids).flatten }

    let(:old_item_ids) { %w[old1 old2] }
    let(:seen_item_ids) { source_item_ids.sample(2) }
    let(:expected_xml) { source_xml.sub(%r{<item>.*</item>}m, kept_items.join("\n")) }
    let(:seen_items_table) { Tables::SeenItems.new(channel: 'sport_tvp_pl') }

    before do
      Timecop.freeze(Time.now - (3 * 24 * 60 * 60)) { seen_items_table.mark_seen(old_item_ids) }
      seen_items_table.mark_seen(seen_item_ids)
    end

    it 'preserves source feed except for duplicate items, marks item ids as seen, deletes old item ids' do
      expect { rss }
        .to change { seen_items_table.seen_ids(old_item_ids + source_item_ids) }
        .from(Set.new(old_item_ids + seen_item_ids))
        .to(Set.new(source_item_ids))
      expect(rss).to eq(expected_xml)
    end
  end
end
