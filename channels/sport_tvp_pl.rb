# frozen_string_literal: true

require 'faraday'
require 'time'
require_relative '../tables/seen_items'

module Channels
  # Fetches and deduplicates the TVP Sport RSS feed, preserving raw XML.
  class SportTvpPl
    RSS_URL = 'http://sport.tvp.pl/sport.tvp.pl/rss+xml.php'
    ITEM_ID_PATTERN = %r{sport\.tvp\.pl/(\d+)/}
    ITEM_PATTERN = %r{<item>.*?</item>}m

    class << self
      def rss(**_params)
        raw_xml = Faraday.get(RSS_URL).body
        items = extract_items(raw_xml)
        kept_items = deduplicate(items)
        rebuild_xml(raw_xml, kept_items)
      end

      private

      def extract_items(xml)
        xml.scan(ITEM_PATTERN).filter_map do |raw_item|
          item_id = raw_item[ITEM_ID_PATTERN, 1]
          { id: item_id, raw: raw_item, pub_date: extract_pub_date(raw_item) } if item_id
        end
      end

      def extract_pub_date(raw_item)
        date_string = raw_item[%r{<pubDate>(.*?)</pubDate>}, 1]
        date_string ? Time.parse(date_string).to_i : 0
      end

      def deduplicate(items)
        unique_items = unique_by_id(items)
        filter_unseen(unique_items)
      end

      def unique_by_id(items)
        items.each_with_object({}) do |item, result|
          item_id = item[:id]
          result[item_id] = item if result[item_id].nil? || item[:pub_date] > result[item_id][:pub_date]
        end
      end

      def filter_unseen(unique_items)
        store = Tables::SeenItems.new(channel: 'sport_tvp_pl')
        store.cleanup!

        all_item_ids = unique_items.keys
        already_seen_item_ids = store.seen_ids(all_item_ids)
        new_item_ids = all_item_ids - already_seen_item_ids.to_a
        store.mark_seen(new_item_ids) unless new_item_ids.empty?

        unique_items.values_at(*new_item_ids)
      end

      def rebuild_xml(xml, kept_items)
        kept_xml = kept_items.map { |item| item[:raw] }.join("\n")
        xml.sub(%r{<item>.*</item>}m, kept_xml)
      end
    end
  end
end
