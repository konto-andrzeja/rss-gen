# frozen_string_literal: true

require 'cgi'
require 'json'
require 'net/http'
require 'nokogiri'
require 'rss'

module Channels
  # Latest videos of the TikTok account `user`, from the page TikTok serves for
  # embedding a profile on other sites. It needs no login, while the HTML of the
  # regular profile page has no videos in it.
  class Tiktok
    BASE_URL = 'https://www.tiktok.com'
    HEADERS = { 'User-Agent' => 'rss-gen/1.0 (personal feed reader)' }.freeze

    class << self
      def rss(**params)
        user = params[:user].to_s[/\A[\w.]+\z/] or raise ArgumentError, 'Invalid TikTok user'
        page = embed_page(user)

        RSS::Maker.make('2.0') do |maker|
          add_channel(maker, user, page)
          videos(page).each { |video| add_item(maker, user, video) }
        end.to_s
      end

      private

      def add_channel(maker, user, page)
        title = "TikTok: #{page.dig('userInfo', 'nickname') || user}"
        maker.channel.title = title
        maker.channel.description = title
        maker.channel.link = "#{BASE_URL}/@#{user}"
      end

      # Anything but a list of videos raises, so a change on TikTok's side shows
      # up as an error instead of an empty feed.
      def embed_page(user)
        response = Net::HTTP.get_response(URI("#{BASE_URL}/embed/@#{user}"), HEADERS)
        response.value
        script = Nokogiri::HTML(response.body, nil, 'UTF-8').at('script#__FRONTITY_CONNECT_STATE__')
        raise 'Unknown TikTok embed page' unless script

        page = JSON.parse(script.text).dig('source', 'data', "/embed/@#{user}")
        raise "No TikTok videos for #{user}" if page.nil? || page['videoList'].to_a.empty?

        page
      end

      # The page puts pinned videos first, whatever their age.
      def videos(page)
        page['videoList'].sort_by { |video| -video['id'].to_i }
      end

      def add_item(maker, user, video)
        link = "#{BASE_URL}/@#{user}/video/#{video['id']}"
        maker.items.new_item do |item|
          item.title = title(video)
          item.link = link
          item.guid.content = link
          item.updated = published_at(video)
          item.description = description(video, link)
        end
      end

      def title(video)
        text = caption(video)
        text.empty? ? "Video from #{published_at(video).strftime('%F')}" : text
      end

      # Many videos have no caption at all.
      def caption(video)
        video['desc'].to_s.strip
      end

      # The page has no dates, but a video id starts with its upload time.
      def published_at(video)
        Time.at(video['id'].to_i >> 32).utc
      end

      # The cover link is signed and stops working after a couple of days.
      def description(video, link)
        html = %(<p><a href="#{link}"><img src="#{CGI.escapeHTML(video['coverUrl'].to_s)}"></a></p>)
        text = caption(video)
        text.empty? ? html : "#{html}<p>#{CGI.escapeHTML(text)}</p>"
      end
    end
  end
end
