OrbitPermissions = share.OrbitPermissions

# Publish project roles
Meteor.publish null, () ->
  OrbitPermissions.project_roles.find {}

# Publish logged-in user's roles
Meteor.publish null, () ->
  fields = {}
  fields[globals.roles_field_name] = 1

  Meteor.users.find {_id: this.userId}, {fields: fields}