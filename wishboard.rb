require 'rubygems'
require 'sinatra'
require 'net/http'
require 'json'

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

  # Build the base title. We will add tag info to it later
  title = "#{params[:user]}'s Wishboard"

  # Set @filter_tags to an empty array, then fill it with the tag content,
  # and build the title info
  @filter_tags = []
  unless filter_tags.length == 0
    @filter_tags = filter_tags.split("/")
    title = "#{title} [#{@filter_tags.join(' + ')}]"
  end

  @title = title
  @user = params[:user]
  @items, @tags, @locations = get_json_content(@user, @filter_tags)

  # Pinboard has a hard limit on their rss feeds, and only allow filtering on 3 tags.
  # So, if we're already 2 deep, we need to wipe out the tags list
  if @filter_tags.length == 2 
    @tags = []
  end

  # We want to show the wishlist content, unless the user doesn't
  # have any content
  if @items.count > 0
    erb :wish
  else
    erb :error, :locals => { :error_msg => "It looks like #{@user} hasn't tagged anything with <code>want#{ " + #{@filter_tags.join(' + ')}" unless @filter_tags.empty? }</code>!" }
  end
end

# Get the array of links for the user
def get_json_content(user, filter_tags)

  # Using the public rss feed for the user
  url = "http://feeds.pinboard.in/json/v1/u:#{URI.encode(user)}/t:want"

  # if we're looking at a second level tag, append it to the url
  if filter_tags
    filter_tags.each do |filter_tag|
      url = "#{url}/t:#{URI.encode(filter_tag)}"
    end
  end

  data = Net::HTTP.get_response(URI.parse(url)).body

  # If the data is empty, the user doesn't exist on Pinboard,
  # so lets just quit while we're ahead.
  if data == ""
    halt erb :error, :locals => { :error_msg => "It looks like the user #{user} does not exist!" }
  end

  items = []
  tags = []
  locations = []
  begin
    # Remove the tag want from the list of tags,
    # strip any extra whitespace, and add a location attribute
    JSON.parse(data).each do |item|
      item['t'].each { |t| t.strip! }
      item['t'].delete_if { |tag| tag == 'want' }

      # Try like hell to parse the url. Assign an error string as a last resort
      begin
        item['l'] = /https?:\/\/(?:[-\w\d]*\.)?([-\w\d]*\.[a-zA-Z]{2,3}(?:\.[a-zA-Z]{2})?)/i.match(item['u'])[1]
      rescue
        item['l'] = "URL Parse error"
      end

      # Add the item's tags 
      item['t'].each do |tag|
        tags << tag unless tags.include? tag or filter_tags.include? tag
      end

      locations << item['l'] unless locations.include? item['l']

      items << item
    end
  rescue
  end
  return items, tags.sort, locations.sort
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
				<div class="description"><%= item['n'] %></div>
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