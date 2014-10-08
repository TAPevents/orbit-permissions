globals = share.globals

emailToUsername = (email) -> email.replace(/@.*/, "")

addUsers = (emails) ->
  _.map emails, (email) ->
    username = emailToUsername(email)

    if Meteor.users.find({username: username}).count() > 0
      Meteor.users.remove({username: username})

    Accounts.createUser({email: email, username: username, password: globals.password})

Meteor.publish null, (x) ->
  if OrbitPermissions.userCan("get-users-roles", "permissions", this.userId)
    return Meteor.users.find()

  this.ready()

  return

Meteor.startup ->
  admins_ids = globals.admins_ids = addUsers globals.admins_emails
  users_ids = globals.users_ids = addUsers globals.users_emails
 
  admins_part_1_ids = _.filter(admins_ids, (x, i) -> i % 2 == 0)

  admins_part_2_docs = _.filter(admins_ids, (x, i) -> i % 2)
  admins_part_2_docs = Meteor.users.find({_id: {$in: admins_part_2_docs}}).fetch()

  OrbitPermissions.addAdmins(admins_part_1_ids[0])
  OrbitPermissions.addAdmins(admins_part_1_ids.splice(1))
  OrbitPermissions.addAdmins(admins_part_2_docs[0])
  OrbitPermissions.addAdmins(admins_part_2_docs.splice(1))