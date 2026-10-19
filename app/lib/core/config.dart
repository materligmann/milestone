/// Base URL of the Milestone API.
/// Override at build time: `flutter run --dart-define=API_URL=http://localhost:3000`.
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://milestone-api.erligmann.dev',
);

const demoEmail = 'demo@milestone.app';
const demoPassword = 'demo1234';
