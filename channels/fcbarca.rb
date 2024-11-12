require_relative 'base_html2rss.rb'

module Channels
  class FCBarca < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://www.fcbarca.com/', title: 'fcbarca.com' },
        selectors: {
          items: { selector: '.news__list > article' },
          title: { selector: 'h3' },
          description: { selector: '.article__meta__content' },
          link: { selector: 'a.article-link', extractor: 'href' },
          enclosure: {
            selector: '.article__image > img',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end
  end
end
