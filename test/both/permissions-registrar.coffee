helpers = share.helpers

Tinytest.add 'Permissions Registrar - register project permission', (test) ->
  perms = helpers.getRandPermsArray(10)

  for perm in perms
    # make sure perms aren't removed after initiating a new registrar
    project_registrar = new OrbitPermissions.Registrar()

    # test chaining
    test.equal project_registrar, project_registrar.definePermission(perm)

  for perm in perms
    test.isTrue "project:#{perm}" in OrbitPermissions.getPermissions()

Tinytest.add 'Permissions Registrar - package name sterilization', (test) ->
  perm = helpers.getRandPermName()
  pack = helpers.getRandPackName()
  new OrbitPermissions.Registrar("package-author:#{pack}")
    .definePermission(perm)
  
  test.isTrue "#{pack}:#{perm}" in OrbitPermissions.getPermissions()

Tinytest.add 'Permissions Registrar - reject permission that isn\'t dash seperated', (test) ->
  pack = helpers.getRandPackName()
  registrar = new OrbitPermissions.Registrar(pack)

  for i in ["PERM", "p a", "-", "d_b"]
    test.throws (-> registrar.definePermission(i)), Meteor.Error

Tinytest.add 'Permissions Registrar - register package/project role', (test) ->
  pack = helpers.getRandPackName()
  other_pack = helpers.getRandPackName()
  role = helpers.getRandRoleName()
  permissions = helpers.getRandPermsArray(10)
  permissions_from_other_pack =
    _.map(helpers.getRandPermsArray(10), (perm) -> "#{other_pack}:#{perm}")

  project_registrar = new OrbitPermissions.Registrar
  pack_registrar = new OrbitPermissions.Registrar pack

  for permission in permissions
    project_registrar.definePermission permission
    pack_registrar.definePermission permission

    # test chaining
    test.equal project_registrar, project_registrar.definePermission(permission)
    test.equal pack_registrar, pack_registrar.definePermission(permission)

  project_registrar.defineRole role, permissions.concat(permissions_from_other_pack)
  pack_registrar.defineRole role, permissions.concat(permissions_from_other_pack)

  test.isTrue "#{pack}:#{role}" of OrbitPermissions.getRoles()
  test.equal OrbitPermissions.getRoles()["project:#{role}"], (_.map permissions, (permission) -> "project:#{permission}").concat(permissions_from_other_pack)
  test.equal OrbitPermissions.getRoles()["#{pack}:#{role}"], (_.map permissions, (permission) -> "#{pack}:#{permission}").concat(permissions_from_other_pack)

Tinytest.add 'Permissions Registrar - redefining role permissions rejected', (test) ->
  pack = helpers.getRandPackName()
  role = helpers.getRandRoleName()
  permissions = helpers.getRandPermsArray(10)

  registrar = new OrbitPermissions.Registrar(pack)

  for permission in permissions
    registrar.definePermission permission

  registrar.defineRole(role, permissions)

  test.throws (() -> registrar.defineRole(role, permissions)), Meteor.Error

Tinytest.add 'Permissions Registrar - invalid role name is rejected', (test) ->
  pack = helpers.getRandPackName()
  roles = ["-", "dg_fdg", "gd:da"]
  permissions = helpers.getRandPermsArray(10)

  registrar = new OrbitPermissions.Registrar(pack)
  for role in roles
    test.throws (-> registrar.defineRole(role, permissions)), Meteor.Error

Tinytest.add 'Permissions Registrar - invalid permission name is rejected from role definition', (test) ->
  pack = helpers.getRandPackName()
  role = helpers.getRandRoleName()
  permissions = ["a:b:c", "a b", "A:b", ":d-d", "-y:-y", "-", "-y"]

  registrar = new OrbitPermissions.Registrar(pack)
  for permission in permissions
    test.throws (-> registrar.defineRole(role, [permission])), Meteor.Error