require 'rss'
require 'sinatra'

Dir['./channels/*.rb'].each { |file| require file }

CHANNEL_CLASSES = {
  footlol: Channels::Footlol,
  realmadryt_pl: Channels::RealMadryt,
  anime24_pl: Channels::Anime24,
  vice_com_physics: Channels::VicePhysics,
  obligacje_pl: Channels::Obligacje,
  tiktok: Channels::Tiktok,
  fcbarca_com: Channels::FCBarca
}

set :bind, '0.0.0.0'
set :port, 8080

get '/' do
  halt 404 if params[:password] != 'ziyLRwYauqOae2V4'

  content_type 'text/xml'
  CHANNEL_CLASSES[params[:id].to_sym].rss(**params)
end
