# frozen_string_literal: true

require 'net/http'
require 'nokogiri'

module Channels
  # Latest posts of the X account `user`, including those it reposted, from
  # FxTwitter's public feed, which often fails and doesn't label reposts.
  class Twitter
    HEADERS = { 'User-Agent' => 'rss-gen/1.0 (personal feed reader)' }.freeze
    ATOM_NAMESPACE = { 'atom' => 'http://www.w3.org/2005/Atom' }.freeze
    # FxTwitter answers 404 in short bursts for accounts it served moments ago.
    # Each failure takes about 3 seconds, which spaces the attempts out.
    ATTEMPTS = 5

    class << self
      def rss(**params)
        user = params[:user].to_s[/\A\w{1,15}\z/] or raise ArgumentError, 'Invalid X user'
        feed = source_feed(user)
        describe_account(feed, user)
        feed.css('item').each { |item| retitle(item, user) }
        feed.to_xml
      end

      private

      # The source titles itself after the author of its first post, often someone
      # else, and names itself as this feed's address, which readers may follow.
      def describe_account(feed, user)
        feed.css('channel > title, channel > image > title').each { |title| title.content = "X: @#{user}" }
        feed.xpath('//atom:link[@rel="self"]', ATOM_NAMESPACE).remove
      end

      # Anything but a feed with posts raises, so a change on FxTwitter's side
      # shows up as an error instead of an empty feed. Its with_replies=1 option
      # only continues the same list of posts, and fails far more often.
      def source_feed(user)
        response = source_response(URI("https://fxtwitter.com/#{user}/feed.xml"))
        response.value
        feed = Nokogiri::XML(response.body, &:strict)
        raise "No X posts for #{user}" if feed.css('item').empty?

        feed
      end

      def source_response(uri)
        response = nil
        ATTEMPTS.times do
          response = Net::HTTP.get_response(uri, HEADERS)
          break unless response.is_a?(Net::HTTPNotFound)
        end
        response
      end

      # A post without text has its link as its title, and only the link shows
      # that a post came from someone else.
      def retitle(item, user)
        link = item.at('link').text
        title = item.at('title')
        title.content = textless_title(item) if title.text == link
        author = link[%r{\Ahttps://x\.com/(\w+)/status/}, 1]
        title.content = "@#{author}: #{title.text}" unless author.nil? || author.casecmp?(user)
      end

      def textless_title(item)
        media = item.at('enclosure')&.[]('type').to_s[/\A(image|video)/, 1]
        media ? "(#{media})" : '(no text)'
      end
    end
  end
end
