# frozen_string_literal: true

require 'json'
require 'net/http'
require 'rss'
require 'time'

module Channels
  # NHK News Web Easy. The article list only loads with the anonymous NHK ONE
  # token that the site hands to every visitor from outside Japan.
  class NhkEasy
    PAGE_URL = 'https://news.web.nhk/news/easy/'
    NEWS_LIST_URL = "#{PAGE_URL}news-list.json".freeze
    # The same request the site's JS (loginAccountlessAbroad) sends visitors to.
    AUTHORIZE_URL = "https://www.web.nhk/tix/build_authorize?#{URI.encode_www_form(
      idp: 'a-alaz', profileType: 'abroad', redirect_uri: PAGE_URL, entity: 'none',
      area: '130', pref: '13', jisx0402: '13101', postal: '1000001'
    )}".freeze
    TOKEN_COOKIE = 'z_at'
    MAX_REDIRECTS = 10
    MAX_ITEMS = 30

    class << self
      def rss(**_params)
        RSS::Maker.make('2.0') do |maker|
          maker.channel.title = 'NHK News Web Easy'
          maker.channel.link = PAGE_URL
          maker.channel.description = 'NHK News Web Easy'
          articles.first(MAX_ITEMS).each { |article| add_item(maker, article) }
        end.to_s
      end

      private

      # news-list.json is [{ "2026-11-02" => [article, ...], ... }].
      def articles
        news_list.flat_map(&:values).flatten.sort_by { |article| article['news_prearranged_time'] }.reverse
      end

      def news_list
        response = get(NEWS_LIST_URL, 'Authorization' => "Bearer #{token}")
        response.value
        JSON.parse(response.body)
      end

      # Follows the anonymous login redirects, carrying cookies between hosts,
      # until NHK sets the access token cookie.
      def token
        cookies = {}
        url = AUTHORIZE_URL
        MAX_REDIRECTS.times do
          url = login_step(url, cookies)
          token = cookies.find { |(_domain, name), _value| name == TOKEN_COOKIE }&.last
          return token if token
          break unless url
        end
        raise 'NHK did not issue an access token'
      end

      # Requests one URL of the login flow and returns where it redirects to.
      def login_step(url, cookies)
        host = URI(url).host
        response = get(url, 'Cookie' => cookie_header(cookies, host))
        store_cookies(cookies, response, host)
        response['location'] && URI.join(url, response['location']).to_s
      end

      def get(url, headers = {})
        Net::HTTP.get_response(URI(url), headers.reject { |_name, value| value.empty? })
      end

      # cookies is { [domain, name] => value }; an empty value deletes the cookie.
      def store_cookies(cookies, response, host)
        Array(response.get_fields('set-cookie')).each do |set_cookie|
          name, value = set_cookie[/\A[^;]*/].split('=', 2).map(&:strip)
          key = [set_cookie[/;\s*domain=\.?([^;\s]+)/i, 1]&.downcase || host, name]
          if value.to_s.empty?
            cookies.delete(key)
          else
            cookies[key] = value
          end
        end
      end

      def cookie_header(cookies, host)
        cookies.select { |(domain, _name), _value| host == domain || host.end_with?(".#{domain}") }
               .map { |(_domain, name), value| "#{name}=#{value}" }.join('; ')
      end

      def add_item(maker, article)
        news_id = article.fetch('news_id')
        maker.items.new_item do |item|
          item.title = article['title']
          item.link = "#{PAGE_URL}#{news_id}/#{news_id}.html"
          item.description = article['title_with_ruby']
          item.updated = published_at(article)
          item.guid.content = news_id
          item.guid.isPermaLink = false
          add_image(item, article)
        end
      end

      # Japan time; the site orders articles by this field.
      def published_at(article)
        Time.strptime("#{article['news_prearranged_time']} +0900", '%Y-%m-%d %H:%M:%S %z')
      end

      # Each article has either its own Easy image or the regular news photo.
      def add_image(item, article)
        url = article[article['has_news_easy_image'] ? 'news_easy_image_uri' : 'news_web_image_uri']
        return if url.to_s.empty?

        item.enclosure.url = url
        item.enclosure.type = 'image/jpeg'
        item.enclosure.length = 0
      end
    end
  end
end
