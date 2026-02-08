# frozen_string_literal: true

require_relative '../database'

module Tables
  # Tracks seen item IDs per channel for cross-request deduplication.
  class SeenItems
    class << self
      def setup!
        Database.db.create_table?(:seen_items) do
          String :channel, null: false
          String :item_id, null: false
          Integer :seen_at, null: false
          primary_key %i[channel item_id]
        end
      end
    end

    def initialize(channel:, retention_seconds: 2 * 24 * 60 * 60)
      @channel = channel
      @retention_seconds = retention_seconds
      @table = Database.db[:seen_items]
    end

    def seen_ids(item_ids)
      @table.where(channel: @channel, item_id: item_ids).select_map(:item_id).to_set
    end

    def mark_seen(item_ids)
      now = Time.now.to_i
      rows = item_ids.map { |id| { channel: @channel, item_id: id, seen_at: now } }
      @table.insert_conflict(:replace).multi_insert(rows)
    end

    def cleanup!
      cutoff = Time.now.to_i - @retention_seconds
      @table.where { seen_at < cutoff }.delete
    end
  end
end
