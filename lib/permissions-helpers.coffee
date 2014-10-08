helpers = share.helpers =
  dashToWhiteSpace: (s) -> s.replace /-/g, " "

  isDashSeparated: (s) -> /^[a-z0-9][a-z0-9\-]*$/.test s

  sterilizePackageName: (name) ->
    if not _.isString name
      name = ""

    # to allow forks we ignore the package owner part of the package name
    name.replace /^.+:/, ""

  sterilizeInputDescription: (input_description, symbol_name) ->
    default_description = {}

    fb_lang = globals.fallback_language

    default_description[fb_lang] =
      name: helpers.ucfirst helpers.dashToWhiteSpace(symbol_name)

    if not _.isObject input_description
      description = default_description
    else if not input_description[fb_lang]?
      description = _.extend {}, input_description, default_description
    else
      description = input_description

    description

  getUserObject: (user) ->
    # Returns undefined for invalid input (not an id or user object) or if user doesn't exist
    if _.isString user
      return Meteor.users.findOne({_id: user})
    else if _.isObject user
      return Meteor.users.findOne({_id: user._id})
    else
      return undefined

  getUserId: (user) ->
    if _.isString user
      return user
    else if _.isObject user
      if _.isString user._id
        return user._id
    else
      return undefined

  sterilizeUsersArray: (users) ->
    if not _.isArray users
      users = [users]

    return _.reduce users, (
        (memo, user) ->
          if (uid = helpers.getUserId(user))?
            memo.push(uid)

          memo
      ), []

  isValidOrbitPermissionsSymbol: (role) ->
    /^[a-z0-9][a-z0-9\-]*:[a-z0-9][a-z0-9\-]*$/.test(role)

  verifyRolesArray: (roles) ->
    for role in roles
      if not @.isValidOrbitPermissionsSymbol role
        throw new Meteor.Error 403, "Invalid role name: `#{role}'"

    roles

  sterilizeRolesArray: (roles) ->
    if _.isString roles
      roles = [roles]

    roles

  getFallbackLanguage: () -> globals.fallback_language

  getLanguage: () ->
    language = @.getFallbackLanguage()

    if Meteor.isServer
      return language

    if Package["tap:i18n"]
      tap_lang = Package["tap:i18n"].TAPi18n.getLanguage()

      if tap_lang
        language = tap_lang

    language

  ucfirst: (string) ->
    string.charAt(0).toUpperCase() + string.slice(1);