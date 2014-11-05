helpers = share.helpers

Permissions = {}
permissionsDep = new Tracker.Dependency

Roles = {}
rolesDep = new Tracker.Dependency

OrbitPermissions = share.OrbitPermissions =
  custom_roles: new Meteor.Collection globals.custom_roles_collection_name

  _reloadCustomRoles: () ->
    custom_roles = {}

    _.each OrbitPermissions.custom_roles.find({}).fetch(), (role) ->
      custom_roles[role._id] = {
        description: role.description
        permissions: role.permissions
      }

    Roles["project-custom"] = custom_roles

    rolesDep.changed()

    return @

  defineCustomRole: (role_name, permissions, description={}, callback) ->
    if not helpers.isDashSeparated(role_name)
      throw new Meteor.Error 403, "Role name should be all lowercase dash-separated"

    description = helpers.sterilizeInputDescription description, role_name
    if Meteor.isServer or @.throwIfUserCant("edit-custom-roles", "permissions")
      if not Roles["project-custom"][role_name]?
        role = {_id: role_name, permissions: permissions, description: description}

        # Latency compensation
        Roles["project-custom"][role_name] = role
        rolesDep.changed()

        @.custom_roles.insert role, (err, _id) ->
          if err?
            delete Roles["project-custom"][role_name]
            rolesDep.changed()

          callback(err, _id)
      else
        throw new Meteor.Error 400, "Project role `#{role_name}' is already defined"

    return @

  undefineCustomRole: (role_name, callback) ->
    if not helpers.isDashSeparated(role_name)
      throw new Meteor.Error 403, "Role name should be all lowercase dash-separated"

    # Latency compensation
    role = Roles["project-custom"][role_name]
    delete Roles["project-custom"][role_name]
    rolesDep.changed()

    if Meteor.isServer or @.throwIfUserCant("edit-custom-roles", "permissions")
      @.custom_roles.remove role_name, (err) ->
        if err?
          Roles["project-custom"][role_name] = role
          rolesDep.changed()

        callback(err)

    return @

  _modifyUsersRoles: (op, users, roles, callback) ->
    if op not in ["delegate", "revoke"]
      throw new Meteor.Error 403, "Unknow operation"

    if not users?
      throw new Meteor.Error 403, "Missing 'users' param"

    if not roles?
      throw new Meteor.Error 403, "Missing 'roles' param"

    users = helpers.sterilizeUsersArray(users)
    roles = helpers.verifyRolesArray(helpers.sterilizeRolesArray(roles))

    if Meteor.isServer or @.throwIfUserCant("delegate-and-revoke", "permissions")
      # If delegate is being called on the server, no permission is required
      if op == "delegate"
        update = {$addToSet: {}}
        update.$addToSet[globals.roles_field_name] = {$each: roles}
      else if op == "revoke"
        update = {$pullAll: {}}
        update.$pullAll[globals.roles_field_name] = roles

      if Meteor.isClient
        # Iterate over each user to fulfill Meteor's 'one update per ID' policy
        async.each users, ((user, callback) ->
          Meteor.users.update {_id: user}, update, callback), callback
      else
        # On the server we can leverage MongoDB's $in operator for performance
        Meteor.users.update {_id:{$in:users}}, update, {multi: true}, callback

    return @

  delegate: (users, roles, callback) ->
    @._modifyUsersRoles "delegate", users, roles, callback

  revoke: (users, roles, callback) ->
    @._modifyUsersRoles "revoke", users, roles, callback

  getUserRoles: (user) ->
    # Returns an empty array if user doesn't exist

    # On the client getUserRoles is a reactive resource that depends on Meteor.user()

    if Meteor.isClient
      if user?
        if not @.userCan("get-users-roles", "permissions")
          # On the client getUserRoles is always for the current user, unless
          # current user has the get-users-roles permission
          throw new Meteor.Error 401, "Can't query permissions of other users"
      else
        user = Meteor.user()

    if not user? # if null or undefined
      return []

    user = helpers.getUserObject user

    if not user? # if user doesn't exist
      return []

    user_roles = user[globals.roles_field_name]
    if not _.isArray user_roles
      user_roles = []

    user_roles

  userCan: (permission, package_name, user) ->
    # On the client userCan is a reactive resource that depends on @.getUserRoles
    # and rolesDep

    # on the client userCan is always for the current user

    # it's a common pitfall to forget to specify the package_name
    if not package_name?
      message = "OrbitPermissions.UserCan(): You must specify package_name"
      console.log "Error: #{message}"
      throw new Meteor.Error 401, message

    rolesDep.depend()

    package_name = helpers.sterilizePackageName(package_name)

    for role in @.getUserRoles(user)
      if role == globals.admin_role
        return true

      [role_package, role_name] = role.split(":")

      if Roles[role_package]?[role_name]?
        if "#{package_name}:#{permission}" in Roles[role_package][role_name].permissions
          return true

    return false

  throwIfUserCant: (permission, package_name, user) ->
    if not @.userCan(permission, package_name, user)
      throw new Meteor.Error 401, "Insufficient permissions"

    return true

  _loopPermissions: (cb) ->
    # cb will be called with (package_name, permission_name, permission_description)
    # permission_description is the reference to the object, hence must not be
    # changed.

    if not _.isFunction cb
      return

    if Meteor.isClient
      # Reactive resource only on the client
      permissionsDep.depend()

    for package_name of Permissions
      for permission of Permissions[package_name]
        cb(package_name, permission, Permissions[package_name][permission])

  _loopRoles: (cb) ->
    # cb will be called with (package_name, role_name, role_permissions, role_description)
    # role_description is the reference to the object, hence must not be
    # changed.

    if not _.isFunction cb
      return

    if Meteor.isClient
      # Reactive resource only on the client
      rolesDep.depend()

    for package_name of Roles
      for role_name of Roles[package_name]
        role_data = Roles[package_name][role_name]

        permissions = role_data.permissions.slice() # protect the permissions array
        cb(package_name, role_name, permissions, role_data.description)

  getPermissions: () ->
    # Returns available permissions in a data structure that can't affect
    # the Permissions object

    permissions = []
    @._loopPermissions (package_name, permission_name, permission_description) ->
      permissions.push "#{package_name}:#{permission_name}"

    permissions

  getRoles: () ->
    # Returns available roles and their permissions in a data structure that
    # can't affect the Roles object

    roles = {}
    @._loopRoles (package_name, role_name, role_permissions, role_description) ->
      roles["#{package_name}:#{role_name}"] = role_permissions

    roles

  isAdmin: (user) -> globals.admin_role in @.getUserRoles(user)

  addAdmins: (users, callback) -> @.delegate(users, globals.admin_role, callback)

  removeAdmins: (users, callback) -> @.revoke(users, globals.admin_role, callback)

OrbitPermissions.Registrar = (package_name="project") ->
  package_name = helpers.sterilizePackageName(package_name)

  if not Permissions[package_name]
    Permissions[package_name] = {}
  package_permissions = Permissions[package_name]

  if not Roles[package_name]
    Roles[package_name] = {}
  package_roles = Roles[package_name]

  @.definePermission = (permission_name, description) ->
    if not helpers.isDashSeparated(permission_name)
      throw new Meteor.Error 403, "Permission name should be all lowercase dash-separated"

    if permission_name of package_permissions
      if _.isObject description
        description = _.extend {}, package_permissions[permission_name], description
      else
        return @

    package_permissions[permission_name] = \
      helpers.sterilizeInputDescription description, permission_name

    permissionsDep.changed()

    return @

  @.defineRole = (role_name, permissions=null, description) ->
    if not helpers.isDashSeparated(role_name)
      throw new Meteor.Error 403, "Role name should be all lowercase dash-separated"

    # update existing role descripition
    if role_name of package_roles
      if permissions?
        throw new Meteor.Error 403, "For security reasons package role's permissions can't be changed."

      if _.isObject description
        package_roles[role_name].description =
          _.extend {}, package_roles[role_name].description, description

        rolesDep.changed()

      return @

    if not _.isArray permissions
      throw new Meteor.Error 403, "When defining a new role, permissions must be an array"

    # Create a new instance of the permissions array that the caller has no reference to
    permissions = permissions.slice()
    permissions = _.reduce permissions, (
        # Note: we don't check for permission existence, might change in the future
        (memo, permission) ->
          if helpers.isValidOrbitPermissionsSymbol permission
            memo.push permission
          else if helpers.isDashSeparated permission
            memo.push "#{package_name}:#{permission}"
          else
            throw new Meteor.Error 403, "OrbitPermissions.defineRole called with an invalid permission: `#{permission}'. Permissions should be prefixed with their package name or be part of the current package."

          memo
      ), []

    package_roles[role_name] = 
      description: helpers.sterilizeInputDescription description, role_name
      permissions: permissions

    rolesDep.changed()

    return @

  return @

OrbitPermissions._reloadCustomRoles()

# Keep track of changes to custom roles
OrbitPermissions.custom_roles.find({}).observe {
  added: (-> OrbitPermissions._reloadCustomRoles()),
  changed: (-> OrbitPermissions._reloadCustomRoles()),
  removed: (-> OrbitPermissions._reloadCustomRoles())
}

(new OrbitPermissions.Registrar("permissions"))
  .definePermission "edit-custom-roles"
  .definePermission "get-users-roles"
  .definePermission "delegate-and-revoke"
  .defineRole "permissions-manager", ["edit-custom-roles", "get-users-roles", "delegate-and-revoke"]
  .defineRole "admin", [] # This is a special role, users that will have it will have all the permission in the system
