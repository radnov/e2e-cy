const { defineConfig } = require('cypress')

module.exports = defineConfig({
  requestTimeout: 20000,
  defaultCommandTimeout: 10000,
  chromeWebSecurity: false,
  video: false,
  env: {
    REPORT_PORTAL_ENABLED: 'false',
    LOGIN_USERNAME: 'admin',
    LOGIN_PASSWORD: 'district',
    allure: 'true',
  },
  numTestsKeptInMemory: 0,
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      return require('./cypress/plugins/index.js')(on, config)
    },
    baseUrl: 'https://whoami.im.radnov.test.c.dhis2.org/e2e-cy-9312',
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    experimentalSessionAndOrigin: true,
  },
})
