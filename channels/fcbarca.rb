require_relative 'base_html2rss.rb'

module Channels
  class FCBarca < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: {
          url: 'https://hook.eu2.make.com/5zkosw6ady74y6ka4978d6fpjnkfuxmg',
          title: 'fcbarca.com',
          description: 'Centrum kibica FC Barcelony',
          language: 'pl'
        },
        selectors: {
          items: { selector: '.news__list > article' },
          title: { selector: 'h3' },
          description: { selector: '.article__meta__content' },
          link: {
            selector: 'a.article-link',
            extractor: 'href',
            post_process: { name: 'gsub', pattern: 'https://hook.eu2.make.com', replacement: 'https://fcbarca.com' }
          },
          enclosure: {
            selector: '.article__image > img',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end

    # HTTP_HEADERS = {
    #   'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0',
    #   'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    #   'Accept-Language' => 'en-US,en;q=0.5',
    #   'Accept-Encoding' => 'gzip, deflate, br, zstd',
    #   'Referer' => 'https://hide.me/',
    #   'DNT' => '1',
    #   'Connection' => 'keep-alive',
    #   'Upgrade-Insecure-Requests' => '1',
    #   'Sec-Fetch-Dest' => 'document',
    #   'Sec-Fetch-Mode' => 'navigate',
    #   'Sec-Fetch-Site' => 'cross-site',
    #   'Sec-Fetch-User' => '?1',
    #   'Priority' => 'u=0, i',
    #   'Pragma' => 'no-cache',
    #   'Cache-Control' => 'no-cache',
    # }
    # HOST = 'https://de.hideproxy.me'
    #
    # class << self
    #   def rss(**_params)
    #     parsed_html = Nokogiri.HTML(html)
    #     RSS::Maker.make('2.0') do |rss_maker|
    #       rss_channel(rss_maker)
    #       parsed_html.css('.news__list > article').map { |article| rss_item(rss_maker, article) }
    #     end.to_s
    #   end
    #
    #   private
    #
    #   def html
    #     client = Faraday.new(url: HOST, headers: { **HTTP_HEADERS, 'Origin' => 'https://hide.me' })
    #     response = client.post('/includes/process.php?action=update',
    #                            'u=fcbarca.com&go=&proxy_formdata_server=de&allowCookies=1&encodeURL=1')
    #     url = URI.parse(response.headers[:location])
    #     cookie = CGI::Cookie::parse(response.headers[:set_cookie]).first.join('=')
    #
    #     client = Faraday.new(url: 'https://de.hideproxy.me', headers: { 'Cookie' => cookie, 'TE' => 'trailers' })
    #     response = client.get(url.request_uri)
    #     url = URI.parse(response.headers[:location])
    #     response = client.get(url.request_uri)
    #     url = URI.parse(response.headers[:location])
    #     client.get(url.request_uri).body
    #   end
    #
    #   def rss_channel(rss_maker)
    #     rss_maker.channel.updated = Time.now.utc.to_s
    #     rss_maker.channel.link = 'https://www.fcbarca.com'
    #     rss_maker.channel.title = 'FCBarca.com'
    #     rss_maker.channel.description = 'Centrum kibica FC Barcelony'
    #   end
    #
    #   def rss_item(rss_maker, article)
    #     item_title = article.css('h3').first.inner_text
    #     rss_maker.items.new_item do |rss_item_maker|
    #       rss_item_maker.link = "#{HOST}#{article.css('a.article-link').first['href']}"
    #       rss_item_maker.title = item_title
    #       rss_item_maker.description = article.css('.article__meta__content').first.inner_text
    #       rss_item_maker.updated = Time.now.utc
    #       rss_item_maker.enclosure.type = 'image/jpeg'
    #       rss_item_maker.enclosure.length = 0
    #       rss_item_maker.enclosure.url = "#{HOST}#{article.css('.article__image > img').first['src']}"
    #       rss_item_maker.guid.content = Digest::SHA1.hexdigest(item_title)
    #       rss_item_maker.guid.isPermaLink = false
    #     end
    #   end
    # end
  end
end
