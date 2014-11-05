# orbit:permissions 

orbit:permissions is a Meteor package that allows the definition of *permissions*
by packages and apps, gathering these permissions into *roles*, and assigning these
roles to users.

*Permissions* are defined by the app or by packages, which use them to define access
restrictions. These permissions are gathered into *roles*. orbit:permissions has two
two types of roles: *package roles* that are defined in the code level, and *custom roles*
that are defined in the database level.

## Changes to Default Meteor Behavior:

1. User entries in the Meteor.users collection gain a new field named
   orbit\_roles corresponding to the user's roles.
2. The currently logged-in user's orbit\_roles field is automatically published
   to the client.
3. The custom roles collection is automatically published to all clients.

## Permissions and Roles Defined by orbit:permissions

### Permissions

* **permissions:delegate-and-revoke**: Needed in order to delegate and revoke user roles.
* **permissions:get-users-roles**: Needed in order to query roles of other users.
* **permissions:edit-custom-roles**: Needed in order to define and undefine custom roles.

### Package Roles and their permissions

* **permissions:admin**:
..* Users with this role will have all the permissions

* **permissions:permissions-manager**:
..* permissions:delegate-and-revoke
..* permissions:get-users-roles
..* permissions:edit-custom-roles

## Getting Started

Once you've installed orbit:permissions on your app you'll probably want to give to
at least one of your users the permission to use it. You can do this in few ways:

By making the user an Admin:

	// The admin role has all permissions in the system
	OrbitPermissions.addAdmins(user_id);

Or by giving the user the permissions-manager role:

	// Allow all permissions related operations by this user
	OrbitPermissions.delegate(user_id, "permissions:permissions-manager");

## API

### Permissions Registrar API

### Permissions/Package Roles Registrar & Custom Roles

**OrbitPermissions.Registrar(package="project") [anywhere]**

Generates a registrar for roles and permissions for the given *package* or for
the project if called with no package:

Example:

  // A permissions registrar for the chat package
	permissions_registrar = new OrbitPermissions.Registrar("chat");

**permissions_registrar.definePermission(permission\_symbol, description) [anywhere]**

Register a permission.

**Permissions should be declared in a code common to the client and server.**

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

Returns the registrar object to allow chaining.

Example:

```coffeescript
permissions_registrar = new OrbitPermissions.Registrar("chat");

permissions_registrar
  .definePermission("remove-message")
  .definePermission("edit-message")
  .definePermission("appoint-manager");
```

**permissions\_registrar.defineRole(role\_name, permissions, description) [anywhere]**

Register a *package role*.

Fails if role\_name is already defined.

**roles should be declared in a code common to the client and server.**

*role\_name* should be all-lower-cased-dash-separated.

*permissions* should be a list of permissions symbols prefixed by the packages
that introduced them and a colon. Example: "orbit-chat:ban-user".

permissions that were registered in the project code are prefixed with "project:".

You can omit the package if it's a permission that has been introduced by this
package. If an unknown role is listed, it just won’t have any effect.

*description* structure: see *permissions_registrar.definePermission*.

Returns the registrar object to allow chaining.

### Custom Roles

**OrbitPermissions.defineCustomRole(role\_name, permissions, description={}, [callback]) [anywhere]**

Set a *custom role*.

**Required permissions on the client: orbit-permissions:edit-custom-roles.**

Custom roles are saved to the orbit_custom_roles collection with their role-name as _id.

*role\_name* should be all-lower-cased-dash-separated.

*permissions*: like *permissions_registrar.defineRole*.

*description* structure: see *permissions_registrar.definePermission*.

*callback:* Optional. If present, called with an error object as the first
argument and, if no error, the _id as the second.

**OrbitPermissions.undefineCustomRole(role\_name, [callback]) [anywhere]**

Undefine a custom role.

**Required permissions on the client: orbit-permissions:edit-custom-roles.**

*callback:* Optional. If present, called with an error object as its argument.

## Delegate/Revoke Roles

**OrbitPermissions.delegate(users, roles, [callback]) [anywhere]**

Delegate *roles* to *users*.

Each role in the roles list should be prefixed as following:

* Package roles should be prefixed with the "package:" example: "chat:super-moderator". 
* Package roles that were defined in the project code should be prefixed with "project:".
* Custom roles should be prefixed with "project-custom:".

**Required permissions on the client: orbit-permissions:delegate-and-revoke.**

*users:* Can be a user object, user_id or a list of user objects and user_ids.

*roles:* a role or a list of roles to revoke.

*callback:* Optional. If present, called with an error object as its argument.

**OrbitPermissions.revoke(users, roles, [callback]) [anywhere]**

Revoke *roles* from *users*.

Roles structure should be as defined in OrbitPermissions.delegate() above.

**Required permissions on the client: orbit-permissions:delegate-and-revoke.**

*users:* Can be a user object, user_id or a list of user objects and user_ids.

*roles:* a role or a list of roles to revoke.

*callback:* Optional. If present, called with an error object as its argument.

**OrbitPermissions.isAdmin(user) [anywhere]**

Equivalent to:

	_.indexOf(OrbitPermissions.getUserRoles(user), "permissions:admin") >= 0

**OrbitPermissions.addAdmins(users, [callback]) [anywhere]**

Equivalent to:

	OrbitPermissions.delegate(users, "permissions:admin", callback)

**OrbitPermissions.removeAdmins(users, [callback]) [anywhere]**

Equivalent to:

	OrbitPermissions.revoke(users, "permissions:admin", callback)

## Checking Permissions

**OrbitPermissions.userCan(permission, permission\_package, user) [anywhere]**

*user* is always required on the server. On the client defaults to current user.

**Required permissions on the client: orbit-permissions:get-users-roles. if querying other users permissions.**

Returns true if user has the permission.

**OrbitPermissions.throwIfUserCant(permission, permission\_package, [user\_id]) [anywhere]**

*user* is always required on the server. On the client defaults to current user.

Throws Meteor.Error(401, "Insufficient permissions") if user don't have the permission.

## Get Info

**OrbitPermissions.getRoles() [anywhere]**

Returns an object with info about all the defined roles.

**OrbitPermissions.getPermissions() [anywhere]**

Returns an object with info about all the defined permissions.

## Helper

orbit:permissions introduces the "can" helper, that works as follow:

```javascript
{{#if can "permission" "package"}}
    Edit
{{/if}}
```

## Testing

    $ meteor test-packages ./
