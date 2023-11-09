require 'sinatra'
require 'rss'
require 'html2rss'

CHANNELS = {
  footlol: {
    channel: { url: 'https://footroll.pl/footlol', title: 'Footlol' },
    selectors: {
      items: { selector: 'div.post' },
      title: { selector: '.title' },
      link: { selector: 'a', extractor: 'href' },
      enclosure: {
        selector: 'img',
        extractor: 'attribute',
        attribute: 'src',
        post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
      }
    }
  },
  realmadryt_pl: {
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
}

set :bind, '0.0.0.0'
set :port, 8080

get '/' do
  halt 404 if params[:password] != 'SOME_PASSWORD'

  content_type 'text/xml'
  Html2rss.feed(CHANNELS[params[:id].to_sym]).to_s
end
