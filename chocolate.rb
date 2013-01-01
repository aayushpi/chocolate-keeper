require 'sinatra'
require 'omniauth-runkeeper'
load 'auth.rb' # Create a file with Environment variables that store your Runkeeper keys.

class SinatraApp < Sinatra::Base
  configure do
    set :sessions, true
    set :inline_templates, true
    # register Sinatra::Flash
  end
  use OmniAuth::Builder do
    provider :runkeeper, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
    #provider :att, 'client_id', 'client_secret', :callback_url => (ENV['BASE_DOMAIN']
  end
  
  get '/' do
    if session[:authenticated] != true
      erb "
      <a href='http://localhost:4567/auth/runkeeper'>Login with Runkeeper</a>
      "
    else
      # erb'<img src="<%= session[:profile]  %>"/>'
      # erb '<p>sup?</p>'
      uri = URI('http://api.runkeeper.com/fitnessActivities')
      params = { :access_token => session[:token]}
      uri.query = URI.encode_www_form(params)

      res = Net::HTTP.get_response(uri)
      puts res.body if res.is_a?(Net::HTTPSuccess)
      session[:activity] = res.body
      erb'<p> <%= session[:activity] %> </p>'
    end
  end
  
  post '/' do
    # flash.now[:notice] = "You can stop rolling your own now."
    redirect "/"
  end
  
  get '/auth/:provider/callback' do
    session[:authenticated] = true
    session[:token] = request.env["omniauth.auth"]["credentials"]["token"]
    redirect "/"
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
  
  get '/logout' do
    session[:authenticated] = false
    redirect '/'
  end
end

SinatraApp.run! if __FILE__ == $0

__END__

@@ layout
<html>
  <head>
    <link href='http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css' rel='stylesheet' />
  </head>
  <body>
    <div class='container'>
      <div class='content'>
        <%= yield %>
      </div>
    </div>
  </body>
</html>

