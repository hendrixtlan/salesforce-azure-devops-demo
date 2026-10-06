const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    collectCoverageFrom: ['force-app/main/default/lwc/**/*.js'],
    coverageDirectory: 'artifacts/lwc-coverage',
    coverageReporters: ['json', 'lcov', 'text', 'clover', 'cobertura']
};
