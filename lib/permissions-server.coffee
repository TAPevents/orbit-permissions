OrbitPermissions = share.OrbitPermissions

# Publish project roles
Meteor.publish null, () ->
  OrbitPermissions.custom_roles.find {}

# Publish logged-in user's roles
Meteor.publish null, () ->
  fields = {}
  fields[globals.roles_field_name] = 1

  Meteor.users.find {_id: this.userId}, {fields: fields}

Meteor.users.allow({
  update: (userId, doc, fieldNames, modifier) ->
    OrbitPermissions.userCan("delegate-and-revoke", "permissions", userId) and \
      (
        ( # delegate
          ("$addToSet" of modifier) and
          ("orbit_roles" of modifier["$addToSet"])
        ) \
        or
        ( # revoke
          ("$pullAll" of modifier) and
          ("orbit_roles" of modifier["$pullAll"])
        )
      )
})

OrbitPermissions.custom_roles.allow({
  insert: (userId, doc) -> OrbitPermissions.userCan("edit-custom-roles", "permissions", userId),
  remove: (userId, doc) -> OrbitPermissions.userCan("edit-custom-roles", "permissions", userId)
})