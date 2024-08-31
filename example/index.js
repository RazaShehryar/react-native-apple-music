import { AppRegistry } from 'react-native';
import { name as appName } from './app.json';
// eslint-disable-next-line import/no-unresolved
import App from './src/App.tsx';

AppRegistry.registerComponent(appName, () => App);
