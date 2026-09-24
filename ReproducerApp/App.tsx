/**
 * Reproducer: AppState never emits `active` when the iOS app uses the
 * UIScene lifecycle (SceneDelegate).
 *
 * Steps: launch the app, background it (Home), then foreground it again.
 * Expected log: background -> active. Actual: `active` never arrives.
 *
 * @format
 */

import { useEffect, useState } from 'react';
import {
  AppState,
  AppStateStatus,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <AppContent />
    </SafeAreaProvider>
  );
}

function timestamp() {
  return new Date().toISOString().slice(11, 23);
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();
  const isDarkMode = useColorScheme() === 'dark';
  const [current, setCurrent] = useState<AppStateStatus>(AppState.currentState);
  const [events, setEvents] = useState<string[]>(() => {
    const line = `${timestamp()} initial currentState: ${AppState.currentState}`;
    console.log(`[AppState] ${line}`);
    return [line];
  });

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextState => {
      const line = `${timestamp()} change -> ${nextState}`;
      console.log(`[AppState] ${line}`);
      setCurrent(nextState);
      setEvents(prev => [...prev, line]);
    });
    return () => subscription.remove();
  }, []);

  const color = isDarkMode ? '#fff' : '#000';

  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: safeAreaInsets.top,
          backgroundColor: isDarkMode ? '#000' : '#fff',
        },
      ]}>
      <Text style={[styles.title, { color }]}>AppState + UIScene</Text>
      <Text style={[styles.subtitle, { color }]}>
        AppState.currentState: {current}
      </Text>
      <Text style={[styles.hint, { color }]}>
        Background the app and bring it back. `active` should appear below.
      </Text>
      <ScrollView style={styles.log}>
        {events.map((line, i) => (
          <Text key={i} style={[styles.logLine, { color }]}>
            {line}
          </Text>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 16,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    marginTop: 16,
  },
  subtitle: {
    fontSize: 16,
    marginTop: 8,
  },
  hint: {
    fontSize: 13,
    opacity: 0.7,
    marginTop: 8,
  },
  log: {
    marginTop: 16,
  },
  logLine: {
    fontFamily: 'Menlo',
    fontSize: 13,
    paddingVertical: 2,
  },
});

export default App;
