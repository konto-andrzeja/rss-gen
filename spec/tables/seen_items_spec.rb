# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../tables/seen_items'

RSpec.describe Tables::SeenItems do
  let(:seen_items) { described_class.new(channel: 'test', retention_seconds:) }
  let(:retention_seconds) { 2 * 24 * 60 * 60 }

  before { described_class.setup! }

  describe '#seen_ids' do
    subject(:seen_ids) { seen_items.seen_ids(item_ids) }

    let(:item_ids) { %w[a b c] }

    context 'when no items were seen' do
      it { is_expected.to be_empty }
    end

    context 'when some items were seen' do
      let(:seen_item_ids) { %w[a b x y] }
      let(:expected_returned_item_ids) { Set.new(item_ids & seen_item_ids) }

      before { seen_items.mark_seen(seen_item_ids) }

      context 'when unseen ids are passed' do
        let(:item_ids) { %w[d e] }

        it { is_expected.to be_empty }
      end

      context 'when seen ids are passed' do
        it { is_expected.to eq expected_returned_item_ids }
      end
    end
  end

  describe '#mark_seen' do
    subject(:mark_seen) { seen_items.mark_seen(item_ids) }

    let(:item_ids) { %w[x y z] }

    it 'marks item ids as seen' do
      expect { mark_seen }.to change { seen_items.seen_ids(item_ids) }.from(be_empty).to(Set.new(item_ids))
    end

    context 'when called again with the same ids' do
      let(:old_timestamp) { Time.now }
      let(:new_timestamp) { old_timestamp + 1 }

      before { Timecop.freeze(old_timestamp) { seen_items.mark_seen(item_ids) } }
      around { |example| Timecop.freeze(new_timestamp) { example.call } }

      it 'refreshes seen_at timestamp' do
        expect { mark_seen }
          .to change { Database.db[:seen_items].where(item_id: item_ids).select_map(:seen_at) }
          .from(Array.new(item_ids.size) { old_timestamp.to_i })
          .to(Array.new(item_ids.size) { new_timestamp.to_i })
      end
    end
  end

  describe '#cleanup!' do
    subject(:cleanup!) { seen_items.cleanup! }

    let(:retention_seconds) { 2 }
    let(:old_item_ids) { %w[old1 old2] }
    let(:new_item_ids) { %w[new1 new2] }
    let(:now) { Time.now }

    before do
      Timecop.freeze(now - 3) { seen_items.mark_seen(old_item_ids) }
      Timecop.freeze(now - 1) { seen_items.mark_seen(new_item_ids) }
    end

    around { |example| Timecop.freeze(now) { example.call } }

    it 'removes old item ids' do
      expect { cleanup! }
        .to change { seen_items.seen_ids(old_item_ids + new_item_ids) }
        .from(match_array(old_item_ids + new_item_ids))
        .to(match_array(new_item_ids))
    end
  end
end
