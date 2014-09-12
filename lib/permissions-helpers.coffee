share.helpers =
  dashToWhiteSpace: (s) -> s.replace /-/g, " "

  isDashSeparated: (s) -> not /^[a-z\-]$/.test s

  sterilizePackageName: (name) ->
    # to allow forks we ignore the package owner part of the package name
    name.replace /^.+:/, ""

  sterilizeInputDescription: (input_description, symbol_name) ->
    default_description = {en: {name: helpers.dashToWhiteSpace symbol_name}}

    if not _.isObject input_description
      description = default_description
    else if not input_description.en?
      description = _.extend {}, input_description, default_description.en
    else if not input_description.en.name?
      en = _.extend {}, input_description.en, default_description.en
      description = _.extend {}, input_description, default_description.en

    description

  getUserObject: (user) ->
    if _.isString user
      return Meteor.users.find({_id: user});
    else if _.isObject user
      return user
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
    if _.isString users
      users = [users]

    return _.reduce users, (
        (memo, user) ->
          if (uid = helpers.getUserId(user))?
            memo.push(uid)

          memo
      ), []

  isValidOrbitPermissionsSymbol: (role) ->
    /([a-z\-]+):([a-z\-]+)/.test(role)

  verifyRolesArray: (roles) ->
    for role in roles
      if not @.isValidOrbitPermissionsSymbol role
        throw new Meteor.Error 403, "Invalid role name: `#{role}'"

  sterilizeRolesArray: (roles) ->
    if _.isString roles
      roles = [roles]

    roles
