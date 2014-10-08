helpers = share.helpers
globals = share.globals

admins_ids = users_ids = null
Meteor.startup ->
  admins_ids = globals.admins_ids
  users_ids = globals.users_ids

Tinytest.add 'Permissions Delegation/Revocation/Check - admins that were added on setup, are admins', (test) ->
  # This test covers isAdmin/addAdmins/delegate/getUserRoles
  for id in admins_ids
    test.isTrue OrbitPermissions.isAdmin(id)