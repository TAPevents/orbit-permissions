globals = share.globals
helpers = share.helpers

emailAddressToUserId = helpers.emailAddressToUserId
emailAddressToUserObject = helpers.emailAddressToUserObject

logoutAndLoginWithPassword = (email, password, cb) ->
  Meteor.logout ->
    Meteor.loginWithPassword email, password, () ->
      Meteor.setTimeout (() -> cb()), 200

Tinytest.addAsync 'Custom Roles - users without the permissions:edit-custom-roles permission, can\'t add/remove custom role', (test, ready) ->
  # Guest
  test.throws (-> OrbitPermissions.defineCustomRole "new_role", ["test-pack-a:a0", "test-pack-b:a1"]), Meteor.Error

  # User without the permissions:edit-custom-roles
  Meteor.loginWithPassword globals.users_emails[0], globals.password, () ->
    test.throws (-> OrbitPermissions.defineCustomRole "new_role", ["test-pack-a:a0", "test-pack-b:a1"]), Meteor.Error

    Meteor.logout ->
      ready()

Tinytest.addAsync 'Custom Roles - give user the permissions:edit-custom-roles then see whether he can define/undefine custom role', (test, ready) ->
  can_templates_output = {}

  for i in [0, 1]
    do (i) ->
      for pack in ["a", "b"]
        do (pack) ->
          for template in ["a", "b", "c"]
            do (template) ->
              Tracker.autorun ->
                console.log("reload can_#{template}#{i}_test_pack_#{pack}")
                can_templates_output["can_#{template}#{i}_test_pack_#{pack}"] = Blaze.toHTML(Template["can_#{template}#{i}_test_pack_#{pack}"])

  # User without the permissions:edit-custom-roles
  Meteor.loginWithPassword globals.admins_emails[0], globals.password, () ->
    OrbitPermissions.delegate emailAddressToUserId(globals.users_emails[0]), "permissions:permissions-manager", ->
      Meteor.logout ->
        Meteor.loginWithPassword globals.users_emails[0], globals.password, () ->
          test.isTrue OrbitPermissions.userCan("edit-custom-roles", "permissions")

          postRoleDefinition = ->
            test.equal OrbitPermissions.getRoles()["project-custom:#{globals.custom_roles[0]}"], ["test-pack-b:a0", "test-pack-b:b0"]

            test.isFalse OrbitPermissions.userCan("a0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
            test.isFalse OrbitPermissions.userCan("b0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
            test.isFalse OrbitPermissions.userCan("c0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))

            logoutAndLoginWithPassword globals.users_emails[1], globals.password, ->
              test.isFalse OrbitPermissions.userCan("a0", "test-pack-b")
              test.equal can_templates_output.can_a0_test_pack_b, "can't"
              test.isFalse OrbitPermissions.userCan("b0", "test-pack-b")
              test.equal can_templates_output.can_b0_test_pack_b, "can't"
              test.isFalse OrbitPermissions.userCan("c0", "test-pack-b")
              test.equal can_templates_output.can_c0_test_pack_b, "can't"

              logoutAndLoginWithPassword globals.users_emails[0], globals.password, ->
                OrbitPermissions.delegate emailAddressToUserObject(globals.users_emails[1]), "project-custom:#{globals.custom_roles[0]}", ->
                  test.isTrue OrbitPermissions.userCan("a0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                  test.isTrue OrbitPermissions.userCan("b0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                  test.isFalse OrbitPermissions.userCan("c0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))

                  logoutAndLoginWithPassword globals.users_emails[1], globals.password, ->
                    test.isTrue OrbitPermissions.userCan("a0", "test-pack-b")
                    test.equal can_templates_output.can_a0_test_pack_b, "can"
                    test.isTrue OrbitPermissions.userCan("b0", "test-pack-b")
                    test.equal can_templates_output.can_b0_test_pack_b, "can"
                    test.isFalse OrbitPermissions.userCan("c0", "test-pack-b")
                    test.equal can_templates_output.can_c0_test_pack_b, "can't"

                    logoutAndLoginWithPassword globals.users_emails[0], globals.password, ->
                      OrbitPermissions.revoke emailAddressToUserId(globals.users_emails[1]), "project-custom:#{globals.custom_roles[0]}", ->
                        test.isFalse OrbitPermissions.userCan("a0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                        test.isFalse OrbitPermissions.userCan("b0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                        test.isFalse OrbitPermissions.userCan("c0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))

                        logoutAndLoginWithPassword globals.users_emails[1], globals.password, ->
                          test.isFalse OrbitPermissions.userCan("a0", "test-pack-b")
                          test.equal can_templates_output.can_a0_test_pack_b, "can't"
                          test.isFalse OrbitPermissions.userCan("b0", "test-pack-b")
                          test.equal can_templates_output.can_b0_test_pack_b, "can't"
                          test.isFalse OrbitPermissions.userCan("c0", "test-pack-b")
                          test.equal can_templates_output.can_c0_test_pack_b, "can't"

                          logoutAndLoginWithPassword globals.users_emails[0], globals.password, ->
                            # delegate it again, this time, undefine the custom role to see whether as a result
                            # the user stop having the permissions
                            OrbitPermissions.delegate emailAddressToUserObject(globals.users_emails[1]), "project-custom:#{globals.custom_roles[0]}", ->
                              test.isTrue OrbitPermissions.userCan("a0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                              test.isTrue OrbitPermissions.userCan("b0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                              test.isFalse OrbitPermissions.userCan("c0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))

                              logoutAndLoginWithPassword globals.users_emails[1], globals.password, ->
                                test.isTrue OrbitPermissions.userCan("a0", "test-pack-b")
                                test.equal can_templates_output.can_a0_test_pack_b, "can"
                                test.isTrue OrbitPermissions.userCan("b0", "test-pack-b")
                                test.equal can_templates_output.can_b0_test_pack_b, "can"
                                test.isFalse OrbitPermissions.userCan("c0", "test-pack-b")
                                test.equal can_templates_output.can_c0_test_pack_b, "can't"

                                logoutAndLoginWithPassword globals.users_emails[0], globals.password, ->
                                  OrbitPermissions.undefineCustomRole globals.custom_roles[0], ->
                                    test.isTrue ("project-custom:#{globals.custom_roles[0]}" not in OrbitPermissions.getRoles())

                                    test.isFalse OrbitPermissions.userCan("a0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                                    test.isFalse OrbitPermissions.userCan("b0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))
                                    test.isFalse OrbitPermissions.userCan("c0", "test-pack-b", emailAddressToUserObject(globals.users_emails[1]))

                                    logoutAndLoginWithPassword globals.users_emails[1], globals.password, ->
                                      test.isFalse OrbitPermissions.userCan("a0", "test-pack-b")
                                      test.equal can_templates_output.can_a0_test_pack_b, "can't"
                                      test.isFalse OrbitPermissions.userCan("b0", "test-pack-b")
                                      test.equal can_templates_output.can_b0_test_pack_b, "can't"
                                      test.isFalse OrbitPermissions.userCan("c0", "test-pack-b")
                                      test.equal can_templates_output.can_c0_test_pack_b, "can't"

                                      logoutAndLoginWithPassword globals.users_emails[0], globals.password, ->
                                        OrbitPermissions.revoke emailAddressToUserId(globals.users_emails[1]), "project-custom:#{globals.custom_roles[0]}", ->
                                          OrbitPermissions.revoke Meteor.user(), "permissions:permissions-manager", ->
                                            Meteor.logout ->
                                              ready()

          test.equal OrbitPermissions.defineCustomRole(globals.custom_roles[0], ["test-pack-b:a0", "test-pack-b:b0"], null, postRoleDefinition), OrbitPermissions
