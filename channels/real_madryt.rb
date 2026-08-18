require_relative 'base_html2rss.rb'

module Channels
  class RealMadryt < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://www.realmadryt.pl/aktualnosci', title: 'realmadryt.pl' },
        selectors: {
          items: { selector: '.news-tile' },
          title: { selector: '.news-tile__title' },
          description: { selector: '.news-tile__lead' },
          link: { selector: '.news-tile__title a', extractor: 'href' },
          updated: { selector: 'time', extractor: 'attribute', attribute: 'datetime' },
          enclosure: {
            selector: 'img.card__img',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end
  end
end
