require_relative 'base_html2rss.rb'

module Channels
  class RealMadryt < BaseHtml2rss
    def self.config(**_params)
      {
        channel: { url: 'https://www.realmadryt.pl/aktualnosci', title: 'realmadryt.pl' },
        selectors: {
          items: { selector: '.news-article' },
          title: { selector: 'h4' },
          description: { selector: 'p' },
          link: { selector: 'h4 a', extractor: 'href' },
          enclosure: {
            selector: 'img',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end
  end
end
