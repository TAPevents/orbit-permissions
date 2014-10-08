globals = share.globals = 
  admins_emails: ("orbit-permissions-test-admin#{num}@e.com" for num in [0...10]),
  users_emails: ("orbit-permissions-test-user#{num}@e.com" for num in [0...10]),
  custom_roles: ("custom-role#{num}" for num in [0...10]),
  password: "password",
  admins_ids: [], # initiated by (server|client)/setup.coffee 
  users_ids: [] # initiated by (server|client)/setup.coffee