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
 return tags.sort
end

__END__

@@ layout
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title><%= @title %></title>
	<link rel="stylesheet" href="/reset.css" type="text/css" media="all" charset="utf-8">
  <link rel="stylesheet" href="/style.css" type="text/css" media="all" charset="utf-8">
</head>
<body>
  <div id="banner">
    <a href="/">wishboard</a>
  </div>
  <%= yield %>
</body>
</html>

@@ wish

<div id="content">
  <div id="left-column">
	  <h1><%= @user %>'s Wishboard:</h1>
	  <ol>
			<% @items.each do |item| %>
			<li class="wishlist-item">
				<h2><a href="<%= item['u'] %>"><%= item['d'] %></a></h2>
				<% unless item['n'] == "" %>
					<span class="description"><%= item['n'] %></span>
				<% end %>
				<div>
					<% item['t'].each do |tag| %>
						<% tag = tag.strip %>
						<% unless tag == "want" %>
							<a href="/<%= @user %>/<%= tag %>" class="tag"><%= tag %></a>
						<% end %>
					<% end %>
				</div>
			</li>
			<% end %>
		</ol>
  </div>
  <div id="nav">
		<% unless @tags.length == 0 %>
			<span id="nav_header">Filter by tag</span>
			<ol>
				<% @tags.each do |tag| %>
				<li><a href="/<%= @user %>/<%= tag %>"><%= tag %></a></li>
				<% end %>
			</ol>
		<% else %>
			<div><a href="/<%= @user %>">Return</a></div>
		<% end %>
  </div>
</div>