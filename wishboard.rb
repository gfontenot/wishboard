require 'rubygems'
require 'sinatra'
require 'net/http'
require 'json'

get '/' do
  @title = "Wishboard"
  erb :home
end

post '/' do
  redirect "/#{params[:user]}"
end

get '/:user' do
  @title = "#{params[:user]}'s Wishboard"
  @user = params[:user]
  @items = get_json_content(@user)
  @tags = get_related_tags(@items)

  unless @items.count > 0
    erb :error
  else
    erb :wish
  end
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
  items = []
  begin
    JSON.parse(data).each do |item|
      item['t'].each { |t| t.strip! }
      item['t'].delete_if { |tag| tag == 'want' }
      items << item
    end
  rescue
  end
  return items
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

  <link href='http://fonts.googleapis.com/css?family=Inconsolata' rel='stylesheet' type='text/css'>

  <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-7976262-7']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();

  </script>

</head>
<body>
  <div id="banner">
    <a href="/">wishboard</a>
  </div>
  <div id="content">
    <%= yield %>
  </div>
</body>
</html>

@@ home
<p>
  Wishboard is a single-file <a href="http://www.sinatrarb.com/">Sinatra</a> app that generates a wishlist based on a user's <a href="http://pinboard.in">Pinboard</a> account. If you have a pinboard account, you can generate your own wishlist here automatically by tagging items with <code>want</code>. If you know the wishlist that you want to see, you can get there either by using the form on this page, or by going directly to <code>wishboard.heroku.com/[pinboard-username]</code>.
</p>
<p>
  All the source code for this site is hosted on <a href="http://github.com/gfontenot/wishboard">GitHub</a>, and the app itself is hosted on a free instance at <a href="http://heroku.com">Heroku</a>. If you would just like to see an example of what a wishlist looks like here, you can <a href="/gfontenot">look at mine</a>.
</p>

<div id="user-jump">
  <h1 id="main-headline">View a user's wishboard</h1>
  <form action="/" method="post">
    <input type="text" name="user" id="user" placeholder="Pinboard Username"/>
    <input type="submit" name="submit" value="➜"/>
  </form>
</div>

@@ error
<h1>Oops!</h1>
<p>
  Either <%= @user %> hasn't tagged anything with <code>want</code>, or there isn't a pinboard user with that name.
</p>
<p><a href="/">Go home and try again!</a></p>


@@ wish
<div id="left-column">
  <h1><%= @user %>'s Wishboard:</h1>
  <h3><%= @items.count %> items</h3>
  <ol>
		<% @items.each do |item| %>
		<li class="wishlist-item">
			<h2><a href="<%= item['u'] %>"><%= item['d'] %></a></h2>
			<% unless item['n'] == "" %>
				<span class="description"><%= item['n'] %></span>
			<% end %>
			<div>
				<% item['t'].each do |tag| %>					
					<a href="/<%= @user %>/<%= tag %>" class="tag"><%= tag %></a>
				<% end %>
			</div>
		</li>
		<% end %>
	</ol>
</div>
<nav>
	<% unless @tags.length == 0 %>
		<span id="nav_header">Filter by tag</span>
		<ol>
			<% @tags.each do |tag| %>
			<li><a href="/<%= @user %>/<%= tag %>"><%= tag %></a></li>
			<% end %>
		</ol>
	<% else %>
		<a href="/<%= @user %>">Return</a>
	<% end %>
</nav>