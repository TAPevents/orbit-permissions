globals = share.globals

admins_ids = users_ids = null
Meteor.startup ->
  admins_ids = globals.admins_ids
  users_ids = globals.users_ids

Tinytest.addAsync 'Custom Roles - Define and Undefine a Custom Role', (test, ready) ->
  OrbitPermissions.defineCustomRole globals.custom_roles[0], ["test-pack-b:a0", "test-pack-b:b0"], null, ->
    test.equal OrbitPermissions.getRoles()["project-custom:#{globals.custom_roles[0]}"], ["test-pack-b:a0", "test-pack-b:b0"]
    test.equal OrbitPermissions.custom_roles.find({}).count(), 1
    OrbitPermissions.undefineCustomRole globals.custom_roles[0], ->
      test.equal OrbitPermissions.custom_roles.find({}).count(), 0
      test.isTrue ("project-custom:#{globals.custom_roles[0]}" not in OrbitPermissions.getRoles())
      ready()