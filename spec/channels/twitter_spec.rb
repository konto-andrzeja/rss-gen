# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../channels/twitter'

RSpec.describe Channels::Twitter do
  let(:source_url) { 'https://fxtwitter.com/Some_One/feed.xml' }
  let(:other_post) do
    <<~XML
      <item><title>Zażółć &amp; co</title><link>https://x.com/other/status/2</link>
      <guid isPermaLink="true">https://x.com/other/status/2</guid><pubDate>Sun, 08 Nov 2026 18:38:15 GMT</pubDate>
      <enclosure url="https://video.example/2.mp4?tag=29" length="0" type="video/mp4"/>
      <media:thumbnail url="https://image.example/2.jpg"/>
      <description><![CDATA[<p>Zażółć &amp; co</p>]]></description></item>
    XML
  end
  let(:own_post) do
    <<~XML
      <item><title>Mine</title><link>https://x.com/some_one/status/1</link>
      <guid isPermaLink="true">https://x.com/some_one/status/1</guid><pubDate>Sat, 07 Nov 2026 03:50:42 GMT</pubDate>
      <description><![CDATA[<p>Mine</p>]]></description></item>
    XML
  end
  let(:items) { other_post + own_post }
  let(:source) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/"><channel>
      <title>Other Person (@other)</title><link>https://fxtwitter.com/Some_One</link>
      <description>Posts by @Some_One</description>
      <atom:link href="#{source_url}" rel="self" type="application/rss+xml"/>
      <image><url>https://image.example/avatar.jpg</url><title>Other Person (@other)</title>
      <link>https://fxtwitter.com/Some_One</link></image>
      #{items}
      </channel></rss>
    XML
  end

  # Net::HTTP hands over the body as binary, so non-ASCII text relies on the XML's declared encoding.
  before { stub_request(:get, source_url).to_return(body: source.b) }

  describe '.rss' do
    subject(:rss) { described_class.rss(user: 'Some_One') }

    let(:feed) { Nokogiri::XML(rss, &:strict) }

    it 'names the author of a post from someone else, but not of its own, whatever the case' do
      expect(feed.css('item > title').map(&:text)).to eq(['@other: Zażółć & co', 'Mine'])
    end

    context 'with posts that have no text' do
      let(:items) do
        <<~XML
          <item><title>https://x.com/other/status/3</title><link>https://x.com/other/status/3</link>
          <enclosure url="https://image.example/3.jpg" length="0" type="image/jpeg"/></item>
          <item><title>https://x.com/some_one/status/4</title><link>https://x.com/some_one/status/4</link>
          <enclosure url="https://video.example/4.mp4" length="0" type="video/mp4"/></item>
          <item><title>https://x.com/other/status/5</title><link>https://x.com/other/status/5</link></item>
        XML
      end

      it 'titles them by their media instead of their link' do
        expect(feed.css('item > title').map(&:text)).to eq(['@other: (image)', '(video)', '@other: (no text)'])
      end
    end

    it 'titles the feed after the account instead of the author of its first post' do
      expect(feed.css('channel > title, channel > image > title').map(&:text)).to eq(['X: @Some_One'] * 2)
    end

    it 'keeps the rest of the feed as it is' do
      expect(feed.at('channel > image > url').text).to eq('https://image.example/avatar.jpg')
      expect(feed.css('item > guid').map(&:text)).to eq(%w[https://x.com/other/status/2 https://x.com/some_one/status/1])
      expect(feed.at('item > pubDate').text).to eq('Sun, 08 Nov 2026 18:38:15 GMT')
    end

    it 'keeps media and HTML descriptions' do
      expect(feed.at('item > enclosure')['url']).to eq('https://video.example/2.mp4?tag=29')
      expect(rss).to include('<media:thumbnail url="https://image.example/2.jpg"/>')
      expect(rss).to include('<![CDATA[<p>Zażółć &amp; co</p>]]>')
    end

    it "removes the link naming the source as this feed's address" do
      expect(rss).not_to include('rel="self"')
    end

    context 'when the feed has no posts' do
      let(:items) { '' }

      it { expect { rss }.to raise_error('No X posts for Some_One') }
    end

    context 'when the source does not return XML' do
      let(:source) { '<html><body>Please wait<br></body></html>' }

      it { expect { rss }.to raise_error(Nokogiri::XML::SyntaxError) }
    end

    context 'when the source answers 404 a few times first' do
      before { stub_request(:get, source_url).to_return({ status: 404 }, { status: 404 }, { body: source.b }) }

      it 'tries again' do
        expect(feed.css('item').size).to eq(2)
        expect(a_request(:get, source_url)).to have_been_made.times(3)
      end
    end

    context 'when the source keeps answering 404' do
      before { stub_request(:get, source_url).to_return(status: 404) }

      it 'gives up with an error' do
        expect { rss }.to raise_error(Net::HTTPClientException)
        expect(a_request(:get, source_url)).to have_been_made.times(described_class::ATTEMPTS)
      end
    end

    context 'when the source refuses the request' do
      before { stub_request(:get, source_url).to_return(status: 403) }

      it 'does not try again' do
        expect { rss }.to raise_error(Net::HTTPClientException)
        expect(a_request(:get, source_url)).to have_been_made.once
      end
    end

    context 'with an invalid user' do
      subject(:rss) { described_class.rss(user: '../api') }

      it { expect { rss }.to raise_error(ArgumentError, 'Invalid X user') }
    end
  end
end
