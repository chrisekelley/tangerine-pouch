class TabletUser extends Backbone.Model

  url: 'user'

  RECENT_USER_MAX: 3

  initialize: ( options ) ->
    @myRoles = []
    @myName = null

  ###
    Accessors
  ###
  name:        -> @get("name") || null
  roles:       -> @getArray("roles")
  isAdmin:     -> "_admin" in @roles()
  recentUsers: -> Tangerine.settings.getArray("recentUsers")

  ###
    Mutators
  ###
  setPassword: ( pass ) ->

    throw "Password cannot be empty" if pass is ""
    hashes = TabletUser.generateHash(pass)
    salt = hashes['salt']
    pass = hashes['pass']

    @set
      "pass" : pass
      "salt" : salt

    return @

  setId : (name) -> 
    @set
      "_id"  : TabletUser.calcId(name)
      "name" : name

  ###
    Static methods
  ###

  @calcId: (name) -> "user-#{name}"

  @generateHash: ( pass, salt ) ->
    salt = hex_sha1(""+Math.random()) if not salt?
    pass = hex_sha1(pass+salt)
    return {
      pass : pass
      salt : salt
    }


  ###
    helpers
  ###
  verifyPassword: ( providedPass ) ->
    salt     = @get "salt"
    realHash = @get "pass"
    testHash = TabletUser.generateHash( providedPass, salt )['pass']
    return testHash is realHash

  ###
    controller type
  ###

  ghostLogin: (user, pass) ->
    Tangerine.log.db "User", "ghostLogin"
    document.location = Tangerine.settings.location.group.url.replace(/\:\/\/.*@/,'://')+"uploader/_design/uploader/uploader.html?name=#{user}&pass=#{pass}"

  signup: ( name, pass, attributes, callbacks={} ) =>
    @set "_id" : TabletUser.calcId(name)
    @fetch
      success: => @trigger "name-error", "User already exists."
      error: =>
        @set "name" : name
        @setPassword pass
        @save attributes,
          success: =>
            if Tangerine.settings.get("context") is "class"
              view = new RegisterTeacherView
                name : name
                pass : pass
              vm.show view
            else
              @trigger "login"
              callbacks.success?()

  login: ( name, pass, callbacks = {} ) ->
    throw "User already logged in" if $.cookie("user")?
    if _.isEmpty(@attributes) or @get("name") isnt name
      @setId name
      @fetch
        success : =>
          @attemptLogin pass, callbacks
        error : (a, b) ->
          Utils.midAlert "User does not exist."
    else
      @attemptLogin pass, callbacks

  attemptLogin: ( pass, callbacks={} ) ->
    if @verifyPassword pass
      $.cookie "user", @id
      @trigger "login"
      callbacks.success?()
      
      recentUsers = @recentUsers().filter( (a) => !~a.indexOf(@name()))
      recentUsers.unshift(@name())
      recentUsers.pop() if recentUsers.length > @RECENT_USER_MAX
      Tangerine.settings.save "recentUsers" : recentUsers

      return true
    else
      @trigger "pass-error", t("LoginView.message.error_password_incorrect")
      $.cookie "user", null
      callbacks.error?()
      return false

  sessionRefresh: (callbacks) ->
    user = $.cookie "user"
    if user?
      @set "_id": user
      @fetch
       success: ->
        callbacks.success()
    else
      callbacks.success()

  # @callbacks Supports isAdmin, isUser, isAuthenticated, isUnregistered
  verify: ( callbacks ) ->
    if @name() == null
      if callbacks?.isUnregistered?
        callbacks.isUnregistered()
      else
        Tangerine.router.navigate "login", true
    else
      callbacks?.isAuthenticated?()
      if @isAdmin()
        callbacks?.isAdmin?()
      else
        callbacks?.isUser?()

  logout: ->

    @clear()

    $.cookie("AuthSession", null) if $.cookie("AuthSession")?
    $.cookie "user", null

    if Tangerine.settings.get("context") == "server"
      window.location = Tangerine.settings.urlIndex "trunk"
    else
      Tangerine.router.navigate "login", true

    Tangerine.log.app "User-logout", "logout"