(new OrbitPermissions.Registrar("test-pack-a"))
  .definePermission "a0"
  .definePermission "b0"
  .definePermission "c0"
  .definePermission "a1"
  .definePermission "b1"
  .definePermission "c1"
  .defineRole "role-0", ["a0", "b0"]
  .defineRole "role-1", ["a1", "b1"]

(new OrbitPermissions.Registrar("test-pack-b"))
  .definePermission "a0"
  .definePermission "b0"
  .definePermission "c0"
  .definePermission "a1"
  .definePermission "b1"
  .definePermission "c1"
  .defineRole "role-0", ["a0", "b0", "test-pack-a:b0", "test-pack-a:c0"]
  .defineRole "role-1", ["a1", "b1", "test-pack-a:b1", "test-pack-a:c1"]