require 'sinatra'
require 'thin'
require 'json'
require 'omniauth-runkeeper'
require 'faraday'

  configure do
    set :sessions, true
    set :inline_templates, true
  end
  use OmniAuth::Builder do
    provider :runkeeper, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
    #provider :att, 'client_id', 'client_secret', :callback_url => (ENV['BASE_DOMAIN']
  end

  conn = Faraday.new(:url => 'http://api.runkeeper.com') do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end
  
  get '/logout' do
    session[:authenticated] = false
    redirect '/'
  end

  get '/' do
    if session[:authenticated] != true
      erb "
      <a href='/auth/runkeeper'>Login with Runkeeper</a>
      "
    else
      session[:activity]    = conn.get '/fitnessActivities', { :access_token => session[:token] }
      session[:activity]    = JSON.parse session[:activity].body
      erb :activity
    end
  end
  
  get '/auth/:provider/callback' do
    session[:authenticated] = true
    session[:token]         = request.env["omniauth.auth"]["credentials"]["token"]
    redirect "/"
  end

  get '/fitnessActivities/:id' do
      session[:activity]    = conn.get "/fitnessActivities/#{params[:id]}", { :access_token => session[:token],  }    
      erb'<%= session[:activity].body %>'
  end

  get '/json' do
    if session[:authenticated]
      erb '
      <%= session[:activity]["items"] %>
      '
    end
  end
  
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
  
  get '/auth/:provider/deauthorized' do
    erb "#{params[:provider]} has deauthorized this app."
  end
  
  get '/protected' do
    throw(:halt, [401, "Not authorized\n"]) unless session[:authenticated]
    erb "<pre>#{request.env['omniauth.auth'].to_json}</pre><hr>
         <a href='/logout'>Logout</a>"
  end
  
 

__END__


