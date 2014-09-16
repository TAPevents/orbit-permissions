helpers = share.helpers

Tinytest.addAsync 'Permissions Registrar - project permission registration reactivity', (test, ready) ->
  perm = "p" + helpers.getRandPermName()

  perm_defined = false

  invalidatios_count = 0
  tracker = Tracker.autorun () ->
    invalidatios_count += 1

    if perm_defined
      t = "isTrue"
    else
      t = "isFalse"

    test[t] "project:#{perm}" in OrbitPermissions.getPermissions()

    if invalidatios_count == 2
      tracker.stop()
      Meteor.setTimeout (() -> ready()), 0

  project_registrar = new OrbitPermissions.Registrar()

  project_registrar.definePermission(perm)
  test.equal OrbitPermissions.getPermissionsDescriptions()["project:#{perm}"].name, helpers.ucfirst(perm).replace(/-/g, " ")
  perm_defined = true

Tinytest.addAsync 'Permissions Registrar - update existing permission', (test, ready) ->
  perm = helpers.getRandPermName()
  pack = helpers.getRandPackName()

  registrar = new OrbitPermissions.Registrar pack
    .definePermission(perm)

  initiated = false
  Tracker.autorun () ->
    if not initiated
      permissions_descriptions = OrbitPermissions.getPermissionsDescriptions()

      initiated = true
      return

    async.eachSeries ["en", "aa", "bb"],
      (
        (lang_tag, cb) ->
          # for the test to begin we wait for invalidation as a result of
          # permission update
          TAPi18n.setLanguage(lang_tag)
            .done ->
              Tracker.nonreactive ->
                perm_desc = OrbitPermissions.getPermissionsDescriptions()["#{pack}:#{perm}"]
                test.equal perm_desc.name, "NAME-#{lang_tag}"
                test.equal perm_desc.description, "DESCRIPTION-#{lang_tag}"
                cb()
            .fail ->
              cb("Failed to load language")
      ),
      (err) ->
        ready()

  registrar
    .definePermission(perm, {en: {name: "NAME-en", description: "DESCRIPTION-en"}})
    .definePermission(perm, {aa: {name: "NAME-aa", description: "DESCRIPTION-aa"}})
    .definePermission(perm, {bb: {name: "NAME-B", description: "DESCRIPTION-B"}})
    .definePermission(perm, {bb: {name: "NAME-bb", description: "DESCRIPTION-bb"}})

Tinytest.addAsync 'Permissions Registrar - update existing roles description', (test, ready) ->
  pack = helpers.getRandPackName()
  perms = helpers.getRandPermsArray(10)
  role = helpers.getRandRoleName()

  registrar = new OrbitPermissions.Registrar pack

  for perm in perms
    registrar.definePermission perm

  registrar.defineRole role, perms

  initiated = false
  Tracker.autorun () ->
    if not initiated
      role_descriptions = OrbitPermissions.getRolesDescriptions()

      initiated = true
      return

    async.eachSeries ["en", "aa", "bb"],
      (
        (lang_tag, cb) ->
          # for the test to begin we wait for invalidation as a result of
          # permission update
          TAPi18n.setLanguage(lang_tag)
            .done ->
              Tracker.nonreactive ->
                role_desc = OrbitPermissions.getRolesDescriptions()["#{pack}:#{role}"]
                test.equal role_desc.name, "NAME-#{lang_tag}"
                test.equal role_desc.description, "DESCRIPTION-#{lang_tag}"
                cb()
            .fail ->
              cb("Failed to load language")
      ),
      (err) ->
        ready()

  registrar
    .defineRole(role, null, {en: {name: "NAME-en", description: "DESCRIPTION-en"}})
    .defineRole(role, null, {aa: {name: "NAME-aa", description: "DESCRIPTION-aa"}})
    .defineRole(role, null, {bb: {name: "NAME-B", description: "DESCRIPTION-B"}})
    .defineRole(role, null, {bb: {name: "NAME-bb", description: "DESCRIPTION-bb"}})