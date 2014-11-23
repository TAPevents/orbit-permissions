# orbit:permissions 

orbit:permissions is a Meteor package that allows the definition of *permissions*
by packages and apps, gathering these permissions into *roles*, and assigning these
roles to users.

*Permissions* are defined by the app or by packages, which use them to define access
restrictions. These permissions are gathered into *roles*. The orbit:permissions there are two
two types of roles: *package roles* that are defined in the code level, and *custom roles*
that are defined in the database level.

Developed by <a href="http://www.meteorspark.com"><img src="http://www.meteorspark.com/logo/logo-github.png" title="MeteorSpark" alt="MeteorSpark"></a> [Professional Meteor Services](http://www.meteorspark.com)<br/> for <a href="http://tapevents.com/"><img src="http://tapevents.com/images/TAPevents_logo_144px.png" title="TAPevents" alt="TAPevents"></a>&nbsp; [Leading Conference Technology](http://tapevents.com/).

**Table of Contents**

- [orbit:permissions](#orbitpermissions)
  - [Changes to Default Meteor Behavior](#changes-to-default-meteor-behavior)
  - [Permissions and Roles Defined by orbit:permissions](#permissions-and-roles-defined-by-orbitpermissions)
    - [Permissions](#permissions)
    - [Package Roles and their permissions](#package-roles-and-their-permissions)
  - [Getting Started](#getting-started)
  - [API](#api)
    - [The Permissions & Package Roles Registrar](#the-permissions-&-package-roles-registrar)
    - [Custom Roles](#custom-roles)
    - [Delegate/Revoke Roles](#delegaterevoke-roles)
    - [Checking Permissions](#checking-permissions)
    - [Get Info](#get-info)
    - [Templates Helper](#templates-helper)
  - [Testing](#testing)

## Changes to Default Meteor Behavior

1. User entries in the Meteor.users collection gain a new field named
   orbit\_roles corresponding to the user's roles.
2. The currently logged-in user's orbit\_roles field is automatically published
   to the client.
3. The custom roles collection is automatically published to all clients.

## Permissions and Roles Defined by orbit:permissions

### Permissions

The orbit:permissions package defines the following permissions:

* **permissions:delegate-and-revoke**: Needed in order to delegate and revoke user roles.
* **permissions:get-users-roles**: Needed in order to query roles of other users.
* **permissions:edit-custom-roles**: Needed in order to define and undefine custom roles.

The permissions package defines the following package roles:

### Package Roles and their permissions

The orbit:permissions package defines the following Package Roles:

* **permissions:admin**:
  * Users with this role will have all the permissions of all the packages

* **permissions:permissions-manager**:
  * permissions:delegate-and-revoke
  * permissions:get-users-roles
  * permissions:edit-custom-roles

## Getting Started

Once you've installed orbit:permissions on your app you'll probably want to give to
at least one of your users the permission to use it:

By making the user an Admin:

```javascript
// The admin role has all permissions in the system
OrbitPermissions.addAdmins(user); // user can be user_id or user object
```

Or by giving the user the permissions-manager role:

```javascript
// Allow all permissions related operations to be performed by this user
OrbitPermissions.delegate(user, "permissions:permissions-manager"); // user can be user_id or user object
```

## API

### The Permissions & Package Roles Registrar

The permissions and package roles are defined in the code level, the same way mongo
collections are defined in the code level. Once you remove the definition they
stopped being defined.

**OrbitPermissions.Registrar(package="project") [anywhere]**

Generates *package roles* and *permissions* *registrar* for the given *package* or for
the current application if called with no package argument (we treat the application
as just like a package):

Example:

```javascript
// A permissions registrar for the chat package
permissions_registrar = new OrbitPermissions.Registrar("chat");
```

**registrar.definePermission(permission\_symbol, description) [anywhere]**

Register a *permission*.

Returns the registrar object.

**Important!** Permissions should be declared in a code common to the client and server.

*Permission\_symbol* should be all-lower-cased-dash-separated.

*description* structure:

	{
		en: {
			name: "",
			summary: ""
		},
		ru: {
			...
		}
	}

If description is undefined we generate a default one with an English description
that is derived from the permission symbol.

Example:

```javascript
// In a code common to both server and client

permissions_registrar = new OrbitPermissions.Registrar("chat");

permissions_registrar
  .definePermission("remove-message")
  .definePermission("edit-message")
  .definePermission("appoint-manager");
```

**registrar.defineRole(role\_name, permissions, description) [anywhere]**

Register a *package role*.

Returns the registrar object.

**Important!** Roles should be declared in a code common to the client and server.

*role\_name* should be all-lower-cased-dash-separated. Registration will fail if
role\_name is already defined.

*permissions* should be a list of permissions symbols prefixed by the packages
that introduced them and a colon. Example: `orbit-chat:ban-user`.

Permissions that were registered in the application level, should be prefixed with `"project:"`.

You can omit the package name if it's a permission that has been introduced by this
package. If an unknown permission is listed, it won't have any effect.

*description* structure: see *permissions_registrar.definePermission*.

Example 1, defining the *chat-moderator* role for the chat package:

Note that in this example we don't have to prefix the permissions with the package
name, since they were introduced by they belong to the same package of the role.

```javascript
// In a code common to both server and client

(new OrbitPermissions.Registrar("chat"))
  .definePermission("remove-message")
  .definePermission("edit-message")
  .definePermission("appoint-manager")
  .defineRole("chat-moderator", ["edit-message", "remove-message"]);
```

Example 2, define an application role that has some permission of the chat package:

```javascript
// In a code common to both server and client

// Create application registrar.
// Note: To create a registrar for the application itself, we pass no package name as an argument, .
appplication_registrar = new OrbitPermissions.Registrar(); 

appplication_registrar
  .definePermission("approve-accounts")
  .defineRole("site-moderator", ["chat:edit-message", "chat:remove-message", "project:approve-accounts"]);

// note that we could omit the "project:" in "project:approve-accounts", again, because it introduced by
// the same package (this time the package is the app itself).
```

### Custom Roles

*Custom roles* are saved in the client and are not permanent in the code level like the *package roles*.

In order to add or remove custom roles in the client level, the user has to have the
`permissions:edit-custom-roles` permission.

Note that there is no such thing as "custom permissions", permissions are defined by code developers
and are defined in the code level only.

Utilizing orbit:permissions custom roles concept, allows you to give your non-developers app editors,
the power to define new roles.

**OrbitPermissions.defineCustomRole(role\_name, permissions, description={}, [callback]) [anywhere]**

Set a *custom role*.

Returns the OrbitPermissions object.

**Required permissions on the client: permissions:edit-custom-roles.**

Custom roles are saved to the orbit_custom_roles collection with their role-name as _id.

*role\_name* should be all-lower-cased-dash-separated.

*permissions*: Should be structured as explained in *permissions_registrar.defineRole*.

*description* structure: see *registrar.definePermission*.

*callback:* Optional. If present, called with an error object as the first
argument and, if no error, the _id as the second.

Example, define a custom role for a moderator that can remove messages in the chat and approve accounts:

```javascript
// In the server or client
OrbitPermissions.defineCustomRole("underprivileged-moderator", ["project:approve-accounts", "chat:remove-message"]);

// Note that this time the "project:" prefix is required.
```

**OrbitPermissions.undefineCustomRole(role\_name, [callback]) [anywhere]**

Undefine a custom role.

Returns the OrbitPermissions object.

**Required permissions on the client: permissions:edit-custom-roles.**

*callback:* Optional. If present, called with an error object as its argument.

Example:

```javascript
// In the server or client
OrbitPermissions.undefineCustomRole("underprivileged-moderator");
```

### Delegate/Revoke Roles

In orbit:permissions permissions are granted to users indirectly by delegating roles.

In order to add or remove custom roles in the client level, the user has to have the
`permissions:delegate-and-revoke` permission.

**OrbitPermissions.delegate(users, roles, [callback]) [anywhere]**

Delegate *roles* to *users*.

Each role in the roles list should be prefixed as follow:

* *Package roles* should be prefixed with the "package:" example: "chat:super-moderator". 
* Application roles that were defined in the project code should be prefixed with "project:".
* *Custom roles* should be prefixed with "project-custom:".

**Required permissions on the client: permissions:delegate-and-revoke.**

*users:* Can be a user object, user_id or a list of user objects and user_ids.

*roles:* a role or a list of roles to delegate.

*callback:* Optional. If present, called with an error object as its argument.

Example:

```javascript
// In the server or client
OrbitPermissions.delegate(user, ["chat:chat-moderator", "project:site-moderator"]);

// site-moderator is an application role, see its defined in Example 2 of
// registrar.defineRole() above.
```

**OrbitPermissions.revoke(users, roles, [callback]) [anywhere]**

Revoke *roles* from *users*.

Roles structure should be as defined in OrbitPermissions.delegate() above.

**Required permissions on the client: permissions:delegate-and-revoke.**

*users:* Can be a user object, user_id or a list of user objects and user_ids.

*roles:* a role or a list of roles to revoke.

*callback:* Optional. If present, called with an error object as its argument.

Example:

```javascript
// In the server or client
OrbitPermissions.revoke(user, ["chat:chat-moderator", "project:site-moderator"]);
```

**OrbitPermissions.getUserRoles(user) [anywhere]**

Returns all the user's roles, or empty array, if the user has none.

*user* is always required on the server. On the client defaults to current user.

reactive resource.

**OrbitPermissions.isAdmin(user) [anywhere]**

Equivalent to:

```javascript
_.indexOf(OrbitPermissions.getUserRoles(user), "permissions:admin") >= 0
```

**OrbitPermissions.addAdmins(users, [callback]) [anywhere]**

Equivalent to:

```javascript
OrbitPermissions.delegate(users, "permissions:admin", callback)
```

**OrbitPermissions.removeAdmins(users, [callback]) [anywhere]**

Equivalent to:

```javascript
OrbitPermissions.revoke(users, "permissions:admin", callback)
```

### Checking Permissions

**OrbitPermissions.userCan(permission, permission\_package, user) [anywhere]**

*user* is always required on the server. On the client defaults to current user.

**On the client, if querying other users permissions, requires the permissions:get-users-roles permission.**

Returns true if user has *permission* that was defined by the *permission\_package* package.

Example, using userCan to determine whether user is allowed to add *custom roles*:

```javascript
CustomRoles.allow({
  insert: function (userId, doc) {
    return OrbitPermissions.userCan("edit-custom-roles",
                                      "permissions", userId);
  },
  remove: function (userId, doc) {
    return OrbitPermissions.userCan("edit-custom-roles",
                                      "permissions", userId);
  )
});
```

**OrbitPermissions.throwIfUserCant(permission, permission\_package, user) [anywhere]**

*user* is always required on the server. On the client defaults to current user.

Throws Meteor.Error(401, "Insufficient permissions") if user don't have the permission.

### Get Info

**OrbitPermissions.getRoles() [anywhere]**

Returns an object with info about all the defined roles.

**OrbitPermissions.getPermissions() [anywhere]**

Returns an object with info about all the defined permissions.

### Templates Helper

orbit:permissions introduces the "can" helper, that works as follow:

```handlebars
{{#if can "permission" "package"}}
    Edit
{{/if}}
```

## Testing

    $ meteor test-packages ./
