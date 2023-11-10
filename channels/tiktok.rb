require 'faker'
require 'faraday'
require 'nokogiri'

module Channels
  class Tiktok
    class << self
      def rss(**params)
        user_id = params[:user_id]
        html = html(user_id)
        json = JSON.parse(Nokogiri.HTML(html).css('#SIGI_STATE').inner_html)

        RSS::Maker.make('2.0') do |rss_maker|
          rss_channel(rss_maker, user_id)
          json['ItemModule'].values.map { |video_item| rss_item(rss_maker, video_item) }
        end.to_s
      end

      private

      def html(user_id)
        request = Faraday.new(
          url: "https://www.tiktok.com/@#{user_id}?lang=en",
          headers: {
            'User-Agent': Faker::Internet.user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Pragma': 'no-cache',
            'Cache-Control': 'no-cache'
          }
        )
        request.get.body
      end

      def rss_channel(rss_maker, user_id)
        rss_maker.channel.author = user_id
        rss_maker.channel.updated = Time.now.utc.to_s
        rss_maker.channel.link = "https://www.tiktok.com/@#{user_id}?lang=en"
        rss_maker.channel.title = "Tiktok - #{user_id}"
        rss_maker.channel.description = "Tiktok - #{user_id}"
      end

      def rss_item(rss_maker, video_item)
        item_title = video_item['desc'] == '' ? video_item['id'] : video_item['desc']
        rss_maker.items.new_item do |rss_item_maker|
          rss_item_maker.link = "https://www.tiktok.com/@jasonkpargin/video/#{video_item['id']}?lang=en"
          rss_item_maker.title = item_title
          rss_item_maker.updated = Time.at(video_item['createTime'].to_i).utc
          rss_item_maker.enclosure.type = 'image/webp'
          rss_item_maker.enclosure.length = 0
          rss_item_maker.enclosure.url = video_item['video']['dynamicCover']
          rss_item_maker.guid.content = Digest::SHA1.hexdigest(item_title)
          rss_item_maker.guid.isPermaLink = false
        end
      end
    end
  end
end
