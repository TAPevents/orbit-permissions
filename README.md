# orbit-permissions 

orbit-permissions is a Meteor package that allows the definition of permissions
by packages, gathering these permissions into roles, and assigning these roles
to users.

**Permissions** are defined by packages, which use them to define access
restrictions. These permissions are gathered into **roles**, either by the
project manager, *project roles*, or by packages, *package roles*. Roles are
then delegated to users.

Permissions and package roles are stored in-memory, you can alter and remove
them by changing the code, project roles are stored in the db and are meant to
be defined by the project manager.

## Changes to Default Meteor Behavior:

1. User entries in the Meteor.users collection gain a new field named
   orbit\_roles corresponding to the user's roles.
2. The currently logged-in user's orbit\_roles field is automatically published
   to the client.
3. Project roles are automatically published to all clients.

## API

### Permissions Registrar

**OrbitPermissions.Registrar(package) [anywhere]**


**permissions_registrar.definePermission(permission\_symbol, description) [anywhere]**


**permissions_registrar.defineRole(role\_name, permissions, description) [anywhere]**


### Project Roles

**OrbitPermissions.delegate(users, roles) [anywhere]**


**OrbitPermissions.revoke(users, roles) [anywhere]**


### User Roles Managment

**OrbitPermissions.defineProjectRole(role\_name, permissions) [anywhere]**


**OrbitPermissions.undefineProjectRole(role\_name) [anywhere]**


### Checking Permissions

**OrbitPermissions.userCan(permission, permission\_package) [client] [reactive-resource]**
**OrbitPermissions.userCan(permission, permission\_package, user\_id) [server]**

## Helper

```javascript
{{#if can "permission" "package"}}
    Edit
{{/if}}
```
