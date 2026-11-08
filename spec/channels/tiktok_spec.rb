# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../channels/tiktok'

RSpec.describe Channels::Tiktok do
  let(:embed_url) { 'https://www.tiktok.com/embed/@some.one' }
  let(:pinned_time) { Time.utc(2026, 6, 8, 17, 10) }
  let(:latest_time) { Time.utc(2026, 11, 7, 0, 47) }
  let(:pinned_id) { (pinned_time.to_i << 32).to_s }
  let(:latest_id) { (latest_time.to_i << 32).to_s }
  let(:videos) do
    [
      { id: pinned_id, desc: 'Zażółć #książki ', coverUrl: 'https://cdn.example/pinned.image?a=1&b=2' },
      { id: latest_id, desc: '', coverUrl: 'https://cdn.example/latest.image' }
    ]
  end
  let(:state) do
    { source: { data: { '/embed/@some.one': { userInfo: { nickname: 'Some One' }, videoList: videos } } } }
  end
  let(:html) do
    <<~HTML
      <html><head><meta charset="utf-8"></head><body>
      <script id="__FRONTITY_CONNECT_STATE__" type="application/json">#{state.to_json}</script>
      </body></html>
    HTML
  end

  # Net::HTTP hands over the body as binary, so non-ASCII captions rely on the channel's decoding.
  before { stub_request(:get, embed_url).to_return(body: html.b) }

  describe '.rss' do
    subject(:rss) { described_class.rss(user: 'some.one') }

    let(:feed) { RSS::Parser.parse(rss) }

    it 'describes the account' do
      expect(feed.channel.title).to eq('TikTok: Some One')
      expect(feed.channel.link).to eq('https://www.tiktok.com/@some.one')
    end

    it 'lists the videos newest first, dated from their ids' do
      expect(feed.items.map(&:link)).to eq(
        ["https://www.tiktok.com/@some.one/video/#{latest_id}", "https://www.tiktok.com/@some.one/video/#{pinned_id}"]
      )
      expect(feed.items.map(&:pubDate)).to eq([latest_time, pinned_time])
    end

    it 'titles a video by its caption, or by its date without one' do
      expect(feed.items.map(&:title)).to eq(['Video from 2026-11-07', 'Zażółć #książki'])
    end

    it 'keeps the guid stable when the caption or cover changes' do
      expect(feed.items.first.guid.content).to eq(feed.items.first.link)
    end

    it 'shows the cover with the caption' do
      expect(feed.items.last.description).to eq(
        %(<p><a href="#{feed.items.last.link}"><img src="https://cdn.example/pinned.image?a=1&amp;b=2"></a></p>) \
        '<p>Zażółć #książki</p>'
      )
    end

    context 'when the page has no videos' do
      let(:videos) { [] }

      it { expect { rss }.to raise_error('No TikTok videos for some.one') }
    end

    context 'when the page has no state' do
      let(:html) { '<html><body>Please wait</body></html>' }

      it { expect { rss }.to raise_error('Unknown TikTok embed page') }
    end

    context 'when TikTok refuses the request' do
      before { stub_request(:get, embed_url).to_return(status: 403) }

      it { expect { rss }.to raise_error(Net::HTTPClientException) }
    end

    context 'with an invalid user' do
      subject(:rss) { described_class.rss(user: '../api') }

      it { expect { rss }.to raise_error(ArgumentError, 'Invalid TikTok user') }
    end
  end
end
