globals = share.globals
helpers = share.helpers

emailAddressToUserId = helpers.emailAddressToUserId
emailAddressToUserObject = helpers.emailAddressToUserObject

Tinytest.addAsync 'Permissions Delegation/Revocation/Check - login as an admin user, look for the admin role and check arbitrary permission', (test, ready) ->
  Meteor.loginWithPassword globals.admins_emails[0], globals.password, () ->
    test.isTrue OrbitPermissions.isAdmin()
    test.isTrue OrbitPermissions.userCan("arbitrary", "package") # admins can do anything

    Meteor.logout ->
      ready()

Tinytest.addAsync 'Permissions Delegation/Revocation/Check - login as a normal user, make sure isAdmin returns false and have no permission for an arbitrary permission', (test, ready) ->
  Meteor.loginWithPassword globals.users_emails[0], globals.password, () ->
    test.isFalse OrbitPermissions.isAdmin()
    test.isFalse OrbitPermissions.userCan("arbitrary", "package") # admins can do anything
    test.throws (-> OrbitPermissions.addAdmins(Meteor.user()._id)), Meteor.Error

    Meteor.logout ->
      ready()

Tinytest.addAsync 'Permissions Delegation/Revocation/Check - login as an admin, appoint normal user to be an admin then revoke the role', (test, ready) ->
  Meteor.loginWithPassword globals.admins_emails[0], globals.password, () ->
    test.isTrue OrbitPermissions.isAdmin()

    # Make a normal user an admin - user object
    user = emailAddressToUserObject(globals.users_emails[0])

    afterAdminAdded = ->
      test.isTrue OrbitPermissions.isAdmin(user)
      test.equal (OrbitPermissions.removeAdmins user, afterAdminRemoved), OrbitPermissions

    afterAdminRemoved = ->
      test.isFalse OrbitPermissions.isAdmin(user)

      # make him admin again, login as this user, revoke his own admin role
      OrbitPermissions.addAdmins user, -> 
        Meteor.logout ->
          Meteor.loginWithPassword globals.users_emails[0], globals.password, () ->
            test.isTrue OrbitPermissions.isAdmin()

            OrbitPermissions.removeAdmins user, ->
              test.isFalse OrbitPermissions.isAdmin()

              # Can't appoint himself to be an admin again
              test.throws (-> OrbitPermissions.addAdmins Meteor.user()), Meteor.Error

              Meteor.logout ->
                ready()

    test.equal (OrbitPermissions.addAdmins user, afterAdminAdded), OrbitPermissions

Tinytest.addAsync 'Permissions Delegation/Revocation/Check - login as an admin, appoint multiple admins at once, then revoke admin role from all of them', (test, ready) ->
  Meteor.loginWithPassword globals.admins_emails[0], globals.password, () ->
    users_ids = _.map globals.users_emails.slice().splice(0, Math.ceil(globals.users_emails.length / 2)), (email) ->
      emailAddressToUserId(email)
    users_objs = _.map globals.users_emails.slice().splice(Math.ceil(globals.users_emails.length / 2)), (email) ->
      emailAddressToUserObject(email)

    regular_users = users_ids.concat(users_objs)
    OrbitPermissions.addAdmins regular_users, (err) ->
      for user in regular_users
        test.isTrue OrbitPermissions.isAdmin(user)

      OrbitPermissions.removeAdmins regular_users, ->
        for user in regular_users
          test.isFalse OrbitPermissions.isAdmin(user)

      Meteor.logout ->
        ready()

