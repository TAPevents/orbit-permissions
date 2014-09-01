Package.describe({
  name: "orbit:permissions",
  summary: "Package and project permissions and roles managment",
  version: "0.0.1",
  git: "https://github.com/TAPevents/orbit-permissions"
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0.1');

  api.use('coffeescript', both);
  api.use('underscore', both);

  api.addFiles('lib/permissions.coffee', both);
  api.addFiles('lib/permissions-registrar.coffee', both);
});

Package.onTest(function(api) {
  api.versionsFrom('METEOR@0.9.0.1');

  api.use('tinytest');
  api.use('orbit:permissions');

  api.addFiles('test/both/permissions.coffee', both);
  api.addFiles('test/both/permissions-registrar.coffee', both);
});
