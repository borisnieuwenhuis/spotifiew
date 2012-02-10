define ['backbone'], (Backbone) ->
  sp = getSpotifyApi(1)
  models = sp.require("sp://import/scripts/api/models")
  views = sp.require("sp://import/scripts/api/views")
  ui = sp.require("sp://import/scripts/ui");
  player = models.player

  class SongWatcher extends Backbone.Model
    initialize: () ->
      change = _.bind (e) ->
        if e.data.curtrack == true
            track = player.track
            @set
              "track": track
      , @
      player.observe models.EVENT.CHANGE, change

  class SearchSong extends Backbone.Model
    search: (text) =>
      console.log "searching for #{text}"
      @set
        text: text
      search = new models.Search text
      search.localResults = models.LOCALSEARCHRESULTS.APPEND
      console.log search
      search.observe models.EVENT.CHANGE, () =>
        result_count = search.tracks.length
        console.log "found #{result_count} tracks for #{text}"
        if result_count > 0
          random_index = Math.floor result_count*Math.random()
          console.log "now playing #{random_index}"
          player.play search.tracks[random_index].uri
        else
          alert "no tracks found for #{text}"
      search.appendNext();

  songWatcher = new SongWatcher()
  searchSong = new SearchSong()

  class SongPainter extends Backbone.View
    el: $ "#photo_container"
    initialize: () ->
       songWatcher.bind "change:track", @trackChanged, @
    trackChanged: (track) =>
      text = searchSong.get("text")
      apiKey = "901b46f27dc2bd94a0c46c0f96f60d34"
      photo_container = $ @el
      photo_container.empty()
      $.getJSON "http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=#{apiKey}&text=#{text}&format=json&per_page=500&jsoncallback=?", (data) ->
        photos = data.photos.photo
        photos = (_ data.photos.photo).shuffle()
        $.each photos, (j , item) ->
          photoUrl = 'http://farm' + item.farm + '.static.flickr.com/' + item.server + '/' + item.id + '_' + item.secret + '_m.jpg'
          photo_container.append "<img style=\"display: none;\" src=\"#{photoUrl}\">"

        j = 0
        fadeIn = () ->
          photoChild = photo_container.children().get(j)
          $(photoChild).fadeIn 1000, () ->
            j++
            if j < photo_container.children().length
              photoChild.scrollIntoView false
              fadeIn()


        fadeIn()

  songPainter = new SongPainter()

  class AppView extends Backbone.View
    el: "body"
    events:
      "click #login": "showLogin"
    showLogin: () ->
      auth = sp.require 'sp://import/scripts/api/auth'
      auth.authenticateWithFacebook '291638010878776', ['user_about_me', 'user_checkins'],
        onSuccess : (accessToken, ttl) ->
          console.log "Success! Here's the access token: #{accessToken}"
        onFailure : (error) ->
      	  console.log "Authentication failed with error: #{error}"
        onComplete : () ->
          console.log "test"


#      auth.showAuthenticationDialog 'http://www.last.fm/api/auth/?api_key=6d4a18538474e062d75b137e8d829a4f&cb=sp://songquiz', 'sp://songquiz',
#        onSuccess : (response) ->
#      		Response will be something like 'sp://my_app_name?token=xxxxxxx'
#        	console.log "Success! Here's the response URL: #{response}"
#      	onFailure : (error) ->
#      		console.log "Authentication failed with error: #{error}"
#      	onComplete : () ->
#          console.log "complete"

  appView = new AppView()

  class SearchView extends Backbone.View
    el: "#song_selector"
    events:
      "keypress": "keypress"
    keypress: (event) ->
      if event.charCode == 13
        searchSong.search($(event.target).val())

  searchView = new SearchView()
