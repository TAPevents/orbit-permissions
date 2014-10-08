helpers = share.helpers =
  getRandString: -> Math.random().toString(36).substring(10)
  timeStamp: -> new Date().getTime()
  getRandRoleName: -> "role-#{@.getRandString()}-#{@.timeStamp()}"
  getRandPermName: -> "perm-#{@.getRandString()}-#{@.timeStamp()}"
  getRandPackName: -> "pack-#{@.getRandString()}-#{@.timeStamp()}"
  getRandPermsArray: (size) ->
    a = []
    for i in [1...size] by 1
      a.push helpers.getRandPermName()

    return a

  ucfirst: (string) -> string.charAt(0).toUpperCase() + string.slice(1)

  emailAddressToUserObject: (email) -> Meteor.users.findOne({"emails.address": email})
  emailAddressToUserId: (email) -> helpers.emailAddressToUserObject(email)._id