require 'sinatra'
require 'json'
require 'omniauth-runkeeper'
require 'faraday'

class SinatraApp < Sinatra::Base
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
  
  get '/' do
    if session[:authenticated] != true
      erb "
      <a href='/auth/runkeeper'>Login with Runkeeper</a>
      "
    else
      # uri                 = URI('http://api.runkeeper.com/fitnessActivities')
      # params              = { :access_token => session[:token] }
      # uri.query           = URI.encode_www_form(params)
      # res                 = Net::HTTP.get_response(uri)
      # session[:activity]  = JSON.parse res.body
      # conn.request_headers['access_token'] = session[:token]
      puts session[:token]

      session[:activity]    = conn.get '/fitnessActivities', { :access_token => session[:token] }
       # req.headers= {'access_token' => session[:token]}
      # end
      session[:activity] = JSON.parse session[:activity].body
      erb'
      <table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered">
      <thead>
        <tr>
          <th>Duration</th>
          <th>Distance(km)</th>
          <th>Date</th>
          <th>Time</th>
          <th>Type</th>
          <th>Details</th>
        </tr>
      </thead>
      <tbody>
      <% session[:activity]["items"].each do |item| %>
        <tr>
          <th><%= Time.at(item["duration"]).gmtime.strftime("%R:%S")%></th>
          <th><%= (item["total_distance"]/1000) %></th>
          <th><%= DateTime.parse(item["start_time"]).strftime("%a %d %b %Y") %></th>
          <th><%= item["start_time"] %></th>
          <th><%= item["type"] %></th>
          <th><a href="http://localhost:4567<%= item["uri"] %>">Details</a></th>
        </tr>
      <% end %>
      </tbody>
      </table>
      '
    end
  end

  get '/fitnessActivities/:id' do
      session[:activity]    = conn.get "/fitnessActivities/#{params[:id]}", { :access_token => session[:token],  }    
      erb'<%= session[:activity].body %>'
  end

  get '/json' do
    if session[:authenticated]
      erb '
      <%= session[:activity]["items"] %>
      <!-- <h1><%= (DateTime.parse(session[:activity]["items"][0]["start_time"]) - 5).strftime("%d %m %Y") %></h1> -->
      <% if (DateTime.now - 6).strftime("%d %m %Y") == (DateTime.parse(session[:activity]["items"][0]["start_time"]) - 5).strftime("%d %m %Y") %>
      <%= puts "You ran" %>
      <% else %>
      <%= (DateTime.now - 6).strftime("%d %m %Y") %>
      <%= (DateTime.parse(session[:activity]["items"][0]["start_time"]) - 5).strftime("%d %m %Y") %>
      <% end %>
      '
    end
  end
  
  get '/auth/:provider/callback' do
    session[:authenticated] = true
    session[:token]         = request.env["omniauth.auth"]["credentials"]["token"]
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
