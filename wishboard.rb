require 'rubygems'
require 'sinatra'
require 'net/http'
require 'json'
require 'redcarpet'

# Render the home page if we're looking at the root
get '/' do
  @title = "Wishboard"
  erb :home
end

# If we're using the form to get to the user page, redirect accordingly
post '/' do
  redirect "/#{params[:user]}"
end

# Render the user's content based on the username supplied
get '/:user/?*' do |user, filter_tags|
  @user = user
  @filter_tags = filter_tags.split("/")

  @title = page_title

  @items = get_user_items

  @tags = all_tags
  @locations = all_locations

  # Set up our markdown processor for later
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true)

  erb :wish
end

# Get the array of links for the user
def get_user_items

  url = api_url

  # Get the data from the API
  data = Net::HTTP.get_response(URI.parse(url)).body

  # If the data is empty, the user doesn't exist on Pinboard,
  # so lets just quit while we're ahead.
  show_error :no_user if data == ""

  # Remove the 'want' tag and add a location
  items = JSON.parse(data).each do |i|
    i['t'].delete('want')
    i['l'] = URI.parse(i["u"]).host rescue "URL Parse error"
  end rescue show_error(:filter_limit_exceeded)

  # We want to show the wishlist content, unless the user doesn't
  # have any content
  show_error :no_items unless items.count > 0

  items
end

def all_tags
  tags = @items.map { |i| i["t"].map(&:strip) - @filter_tags }
  tags.clear unless @filter_tags.count < 2
  tags.flatten.uniq.sort
end

def all_locations
  locations = @items.map { |i| i['l'] }
  locations.flatten.uniq.sort
end

def page_title
  # Build the base title. We will add tag info to it later
  title = "#{@user}'s Wishboard"

  # Set the filter tags and build the title
  title += " [#{@filter_tags.join(' + ')}]" unless @filter_tags.empty?

  title
end

def api_url
  # Using the public rss feed for the user
  url = "http://feeds.pinboard.in/json/v1/u:#{URI.encode(@user)}/t:want"

  # Add any second level filters to the url
  @filter_tags.each do |filter_tag|
    url += "/t:#{URI.encode(filter_tag)}"
  end

  url
end

def show_error(error)
  error_msgs = {
    :no_user => "It looks like the user #{@user} does not exist!",
    :no_items => "It looks like #{@user} hasn't tagged anything with <code>want#{ " + #{@filter_tags.join(' + ')}" unless @filter_tags.empty? }</code>!",
    :filter_limit_exceeded => "Looks like you have exceeded the limit of 2 tags."
    }
  halt erb :error, :locals => { :error_msg => error_msgs[error] }
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
<p class="intro">
  Wishboard is a single-file <a href="http://www.sinatrarb.com/">Sinatra</a> app that generates a wishlist based on a user's <a href="http://pinboard.in">Pinboard</a> account. If you have a pinboard account, you can generate your own wishlist here automatically by tagging items with <code>want</code>. If you know the wishlist that you want to see, you can get there either by using the form on this page, or by going directly to <code>wishboard.co/[pinboard-username]</code>.
</p>
<p class="intro">
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
  <%= error_msg %>
</p>
<p><a href="/">Go home and try again!</a></p>


@@ wish
<div id="main">
  <h1><a href="/<%= @user %>"><%= @user %>'s Wishboard:</a></h1>
  <h3><%= @items.count %> items<%= " [#{@filter_tags.join(' + ')}]" unless @filter_tags.empty? %></h3>
  <ol>
		<% @items.each do |item| %>
		<li class="wishlist-item">
			<h2><a href="<%= item['u'] %>"><%= item['d'] %></a></h2>
			<% unless item['n'] == "" %>
				<div class="description"><%= @markdown.render(item['n']) %></div>
			<% end %>
      <div class="location">From <em><%= item['l'] %></em></div>
			<ol class="tags">
				<% item['t'].each do |tag| %>
					<li class="tag"><a href="/<%= @user %>/<%= tag %>"><%= tag %></a></li>
				<% end %>
			</ol>
		</li>
		<% end %>
	</ol>
</div>
<nav>
	<% unless @tags.length == 0 %>
		<span id="nav_header">Filter by tag</span>
		<ol>
			<% @tags.each do |tag| %>
			<li><a href="<%= request.url %>/<%= tag %>">+ <%= tag %></a></li>
			<% end %>
		</ol>
	<% else %>
		<a href="/<%= @user %>">Clear Tags</a>
	<% end %>
</nav>