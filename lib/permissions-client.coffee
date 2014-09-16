OrbitPermissions = share.OrbitPermissions
helpers = share.helpers

if Package.ui
  Package.ui.UI.registerHelper globals.helper_name, OrbitPermissions.can

_.extend OrbitPermissions,
  getPermissionsDescriptions: () ->
    language = helpers.getLanguage()
    fallback_language = helpers.getFallbackLanguage()

    permissions = {}
    @._loopPermissions (package_name, permission_name, permission_description) ->
      description = permission_description[fallback_language]

      if language of permission_description
        description = permission_description[language]

      permissions["#{package_name}:#{permission_name}"] = description

    permissions

  getRolesDescriptions: () ->
    language = helpers.getLanguage()
    fallback_language = helpers.getFallbackLanguage()

    roles = {}
    @._loopRoles (package_name, role_name, role_permissions, role_description) ->
      description = role_description[fallback_language]

      if language of role_description
        description = role_description[language]

      roles["#{package_name}:#{role_name}"] = description

    roles