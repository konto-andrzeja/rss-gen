require_relative 'base_html2rss.rb'

module Channels
  class Anime24 < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://anime24.pl/', title: 'anime24.pl' },
        selectors: {
          items: { selector: '#content article.content-card' },
          title: { selector: '.content-card__title' },
          description: { selector: '.content-card__summary' },
          link: { selector: '.content-card__title a', extractor: 'href' },
          updated: { selector: 'time.content-card__date', extractor: 'attribute', attribute: 'datetime' },
          enclosure: {
            selector: 'img.content-card__image',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end
  end
end
