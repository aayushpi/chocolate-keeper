require 'sinatra'
require 'omniauth-runkeeper'


class SinatraApp < Sinatra::Base
  configure do
    set :sessions, true
    set :inline_templates, true
    # register Sinatra::Flash
  end
  use OmniAuth::Builder do
    provider :runkeeper, 'ca1cad429d9d4635b10e9f78d26b7d91', '5d1e07030c0640aa80795221c84193ac'
    #provider :att, 'client_id', 'client_secret', :callback_url => (ENV['BASE_DOMAIN']
  end
  
  get '/' do
    if session[:authenticated] != true
      erb "
      <a href='http://localhost:4567/auth/runkeeper'>Login with Runkeeper</a>
      "
    else
      erb "
      <p>Sup?</p>
      "
    end
  end
  
  post '/' do
    # flash.now[:notice] = "You can stop rolling your own now."
    redirect "/"
  end
  
  get '/auth/:provider/callback' do
    @@user = request.env['omniauth.auth']["info"]["nickname"]
    erb "<p>Hello #{request.env['omniauth.auth']["info"]["nickname"]} <a href='/logout'>Logout</a></p>"

    # Twitter.configure do |config|
      # config.consumer_key = 'akZeVLUrNqzdDkev9Luo6g'
      # config.consumer_secret = '7t7hd4OMUiMzU3xl6K8Z3TMojJXnpHtJWAP7Sw2a8wM'
      # config.oauth_token = request.env["omniauth.auth"]["credentials"]["token"]
      # config.oauth_token_secret = request.env["omniauth.auth"]["credentials"]["secret"]
    # end
    session[:authenticated] = true
    redirect "/"
        # <pre>#{JSON.pretty_generate(request.env['omniauth.auth'])}</pre>
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

