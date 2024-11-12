require_relative 'base_html2rss.rb'

module Channels
  class Obligacje < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://obligacje.pl/pl/emisje', title: 'obligacje.pl' },
        selectors: {
          items: { selector: '.emission-box' },
          title: { selector: '.txt' },
          description: { selector: 'table', extractor: 'html' },
          updated: { selector: '.date', post_process: { name: 'gsub', pattern: 'Zapisy do: ', replacement: '' } },
          link: { extractor: 'static', static: 'https://obligacje.pl/pl/emisje' }
        }
      }
    end
  end
end
