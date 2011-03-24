require 'rubygems'
require 'sinatra'
require 'net/http'
require 'json'

get '/' do
  "Hello World"
end

get '/:user' do
  @title = "#{params[:user]}'s Wishboard"
  @user = params[:user]
  @items = get_json_content(@user)
  @tags = get_related_tags(@items)
  erb :wish
end

get '/:user/:tag' do
  @title = "#{params[:user]}'s Wishboard - [#{params[:tag]}]"
  @user = params[:user]
  filter_tag = params[:tag]
  @items = get_json_content(@user, filter_tag)
  @tags = []
  erb :wish
end

def get_json_content(user, filter_tag = nil)
  url = "http://feeds.pinboard.in/json/v1/u:#{URI.encode(user)}/t:want/"
  unless filter_tag == nil
    url = "#{url}t:#{URI.encode(filter_tag)}"
  end
  data = Net::HTTP.get_response(URI.parse(url)).body
  return JSON.parse(data)
end

def get_related_tags(items)
  tags = []
  items.each do |item|
    item["t"].each do |tag|
      tags << tag.strip unless tag.strip == "want" or tags.include? tag.strip
    end
  end
 return tags
end

__END__

@@ layout
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8">
  <title><%= @title %></title>
  <link rel="stylesheet" href="/style.css" type="text/css" media="screen, projection" charset="utf-8">
</head>
<body>
  <%= yield %>
</body>
</html>

@@ wish

<div id="content">
  <div id="header"><%= @user %>'s Wishboard:</div>
  <div id="left-column">
    <% @items.each do |item| %>
    <div id="wishlist-item">
      <p>
        <div><a href="<%= item['u'] %>" id="item"><%= item['d'] %></a></div>
        <% unless item['n'] == "" %>
          <div id="description"><%= item['n'] %></div>
        <% end %>
        <div>
          <% item['t'].each do |tag| %>
            <% tag = tag.strip %>
            <% unless tag == "want" %>
              <a href="/<%= @user %>/<%= tag %>" id="tag"><%= tag %></a>
            <% end %>
          <% end %>
          </br>
        </div>
        </p>
       </div>
       <div style="clear:both"></div>
      <% end %>
  </div>
  <div id="right-column">
    <div id="nav">
      <% unless @tags.length == 0 %>
        <div id="nav_header">Filter by tag</div>
        <% @tags.each do |tag| %>
        <div><a href="/<%= @user %>/<%= tag %>"><%= tag %></a></div>
        <% end %>
      <% else %>
        <div><a href="/<%= @user %>">Return</a></div>
      <% end %>
    </div>
  </div>
</div>