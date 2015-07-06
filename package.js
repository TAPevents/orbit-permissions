Package.describe({
  name: "orbit:permissions",
  summary: "Package and project permissions and roles managment",
  version: "0.1.1",
  git: "https://github.com/TAPevents/orbit-permissions"
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1.0');

  api.use('tracker', both);
  api.use('coffeescript', both);
  api.use('underscore', both);
  api.use('accounts-base', both);
  api.use('ui', client, {weak: true});

  api.use('tap:i18n@1.0.7', both, {weak: true});

  api.addFiles('lib/async.js', client);
  
  api.addFiles('lib/globals.js', both);
  api.addFiles('lib/permissions-helpers.coffee', both);
  api.addFiles('lib/permissions-common.coffee', both);
  api.addFiles('lib/permissions-client.coffee', client);
  api.addFiles('lib/permissions-server.coffee', server);

  api.export('OrbitPermissions');
});

Package.onTest(function(api) {
  api.versionsFrom('METEOR@1.0');

  api.use('coffeescript', both);
  api.use('tinytest');
  api.use('templating');
  api.use('accounts-password');
  api.use('orbit:permissions');
  api.use('tap:i18n@1.0.7');

  api.addFiles('test/project-tap.i18n', both);

  api.addFiles('test/lib/async.js', client);

  api.addFiles('test/both/globals.coffee', both);
  api.addFiles('test/both/helpers.coffee', both);

  api.addFiles('test/server/setup.coffee', server);

  api.addFiles('test/both/package-permissions.coffee', both);

  api.addFiles('test/both/permissions.coffee', both);

  api.addFiles('test/both/permissions-registrar.coffee', both);
  api.addFiles('test/client/permissions-registrar.coffee', client);

  api.addFiles('test/server/permissions-delegate-revoke-check.coffee', server);
  api.addFiles('test/client/permissions-delegate-revoke-check.coffee', client);

  api.addFiles('test/server/custom-roles.coffee', server);
  api.addFiles('test/client/custom-roles.coffee', client);

  api.addFiles('test/templates/test-can-helper-templates.html', client);

  api.export('OrbitPermissions');
});
