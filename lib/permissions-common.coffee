helpers = share.helpers

Permissions = {}
permissionsDep = new Tracker.Dependency

Roles =  {}
rolesDep = new Tracker.Dependency

OrbitPermissions = share.OrbitPermissions =
  project_roles: new Meteor.Collection globals.project_roles_collection_name

  defineProjectRole: (role_name, permissions, description) ->
    if not Meteor.isServer or @.throwIfUserCant("edit-project-roles", "permissions")
      if not Roles.["project"]?.role_name?
        @.project_roles.insert({_id: role_name, permissions: permissions, description: {}})
      else
        throw new Meteor.Error 400, "Project role `#{role_name}' is already defined"

  undefineProjectRole: (role_name) ->
    if not Meteor.isServer or @.throwIfUserCant("edit-project-roles", "permissions")
      @.project_roles.remove(role_name)

  _modifyUsersRoles: (op, users, roles) ->
    if op not in ["delegate", "revoke"]
      throw new Meteor.Error 403, "Unknow operation"

    if not users?
      throw new Meteor.Error 403, "Missing 'users' param"

    if not roles?
      throw new Meteor.Error 403, "Missing 'roles' param"

    users = helpers.sterilizeUsersArray(users)
    roles = helpers.verifyRolesArray(helpers.sterilizeRolesArray(roles))

    if not Meteor.isServer or @.throwIfUserCant("delegate-and-revoke", "permissions")
      # If delegate is being called on the server, no permission is required
      if op == "delegate"
        update = {$addToSet: {}}
        update.$addToSet[globals.roles_field_name] = {$each: roles}
      else if op == "revoke"
        update = {$pullAll: {}}
        update.$pullAll[globals.roles_field_name] = roles

      if Meteor.isClient
        # Iterate over each user to fulfill Meteor's 'one update per ID' policy
        _.each users, (user) ->
          Meteor.users.update {_id: user}, update
      else
        # On the server we can leverage MongoDB's $in operator for performance
        Meteor.users.update({_id:{$in:users}}, update, {multi: true})

  delegate: (users, roles) ->
    @._modifyUsersRoles "delegate", users, roles

  revoke: (users, roles) ->
    @._modifyUsersRoles "revoke", users, roles

  _getUserRoles: (user) ->
    # On the client userCan is a reactive resource that depends on Meteor.user()
    # and rolesDep

    # on the client userCan is always for the current user
    if Meteor.isClient
      if user?
        throw new Meteor.Error 401, "Can't query permissions of other users"
      user = Meteor.user()

      rolesDep.depend()

    user = helpers.getUserObject user

    if not user?
      return false

    user_roles = user[globals.roles_field_name]
    if not _.isArray user_roles
      user_roles = []

    user_roles

  userCan: (permission, package, user) ->
    # On the client userCan is a reactive resource that depends on @._getUserRoles

    package = helpers.sterilizePackageName(package)

    for role in @._getUserRoles(user)
      if role == globals.admin_role
        return true

      [package, role] = role.split(":")

      if permission in Roles[package]?[role].permissions
        return true

    return false

  throwIfUserCant: (permission, package, user) ->
    if not @.userCan(permission, package, user)
      throw new Meteor.Error 401, "Insufficient permissions"

    return true

  getPermissions: () ->
    # Returns available permissions in a data structure that can't affect
    # the Permissions object

    if Meteor.isClient
      # Reactive resource only on the client
      permissionsDep.depend()

    permissions = []
    for package_name of Permissions
      for permission of Permissions[package_name]
        permissions.push "#{package_name}:#{permission}"

    permissions

  getRoles: () ->
    # Returns available roles and their permissions in a data structure that
    # can't affect the Roles object

    if Meteor.isClient
      # Reactive resource only on the client
      rolesDep.depend()

    roles = {}
    for package_name of Roles
      for role_name of Roles[package_name]
        roles["#{package_name}:#{role_name}"] = Roles[package_name][role_name].permissions.slice()

    roles

  isAdmin: (user) -> globals.admin_role of @._getUserRoles(user)

  addAdmins: (users) -> @.delegate(users, globals.admin_role)

  removeAdmins: (users) -> @.revoke(users, globals.admin_role)

OrbitPermissions.Registrar = (package_name="project") ->
  package_name = helpers.sterilizePackageName(package_name)

  package_permissions = Permissions[package_name] = {}
  package_roles = Roles[package_name] = {}

  @.definePermission = (permission_name, description) ->
    if not helpers.isDashSeparated(permission_name)
      throw new Meteor.Error 403, "Permission name should be all lowercase dash-separated"

    if permission_name of package_permissions
      if _.isObject description
        description = _.extend {}, package_permissions[permission_name], description
      else
        return @

    package_permissions[permission_name] = \
      sterilizeInputDescription description, permission_name

    permissionsDep.changed()

    return @

  @.defineRole = (role_name, options={}) ->
    if not helpers.isDashSeparated(role_name)
      throw new Meteor.Error 403, "Role name should be all lowercase dash-separated"

    if not options?
      throw new Meteor.Error 403, "Missing argument: options"

    permissions = options.permissions
    description = options.description

    if role_name of package_roles
      if permissions?
        throw new Meteor.Error 403, "For security reasons package role's permissions can't be changed."

      if _.isObject description
        description = _.extend {}, package_roles[permission_name].description, options.description

      return @

    if not _.isArray permissions
      throw new Meteor.Error 403, "permissions should be an array"

    # Create a new instance of the permissions array that the caller has no reference to
    permissions = permissions.slice()

    permissions = _.reduce permissions, (
        (memo, permission) ->
          if ":" in permission
            memo.push permission
          else if permission of package_permissions
            memo.push "#{package_name}:#{permission}"
          else
            throw new Meteor.Error 403, "OrbitPermissions.defineRole called with an invalid permission: `#{permission}'. Permissions should be prefixed with their package name or be part of the current package."

          memo
      ), []

    package_roles[role_name] = 
      description: sterilizeInputDescription description, role_name
      permissions: permissions

    rolesDep.changed()

    return @

  return @

(new OrbitPermissions.Registrar("permissions"))
  .definePermission "edit-project-roles"
  .definePermission "delegate-and-revoke"
  .defineRole "permissions-manager", {permissions: ["edit-project-roles", "delegate-and-revoke"]}
  .defineRole "admin", {permissions: []} # This is a special role, users that will have it will have all the permission in the system