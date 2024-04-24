import React, { useEffect, useState } from 'react';
import { View, Text, Switch, StyleSheet, NativeEventEmitter } from 'react-native';
import { Picker } from '@react-native-picker/picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { NativeModules } from 'react-native';
import type { RootStackParamList } from './App';

const { AudioEngineModule } = NativeModules;
const audioEngineEvents = new NativeEventEmitter(AudioEngineModule);

export const RoomPage = ({
  route,
}: NativeStackScreenProps<RootStackParamList, 'RoomPage'>) => {
  const { url, token } = route.params;
  const [subscribers, setSubscribers] = useState('');
  const [isSwitchEnabled, setIsSwitchEnabled] = useState(false);
  const [selectedVoice, setSelectedVoice] = useState("baby");

  useEffect(() => {
    // Initialize connection
    AudioEngineModule.connectToRoom(url, token);

    // Set up the event listener for onTrackSubscribed
    const subscription = audioEngineEvents.addListener(
      'onTrackSubscribed',
      (subscriberName: string) => {
        setSubscribers((prevNames) => {
          return prevNames ? `${prevNames}, ${subscriberName}` : subscriberName;
        });
      }
    );

    // Cleanup the event listener
    return () => subscription.remove();
  }, [url, token]);

  useEffect(() => {
    AudioEngineModule.loadVoice(selectedVoice);
  }, [selectedVoice]);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Users</Text>
      <Text style={styles.subscriberText}>{subscribers}</Text>
      <Text style={styles.label}>Voicemod</Text>
      <Switch
        onValueChange={(value) => {
          setIsSwitchEnabled(value);
          AudioEngineModule.enableVoicemod(value);
        }}
        value={isSwitchEnabled}
      />
      <Picker
        selectedValue={selectedVoice}
        style={styles.picker}
        onValueChange={(itemValue) => setSelectedVoice(itemValue)}
      >
        <Picker.Item label="Baby" value="baby" />
        <Picker.Item label="Blocks" value="blocks" />
        <Picker.Item label="Cave" value="cave" />
        <Picker.Item label="Deep" value="deep" />
        <Picker.Item label="Magic chords" value="magic-chords" />
        <Picker.Item label="Out of range" value="out-of-range" />
        <Picker.Item label="Pilot" value="pilot" />
        <Picker.Item label="Speechifier" value="speechifier" />
        <Picker.Item label="Trap Tune" value="trap-tune" />
      </Picker>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF', 
  },
  subscriberText: {
    marginBottom: 20, 
    color: '#000000', 
  },
  label: {
    fontSize: 16, 
    fontWeight: 'bold', 
    marginBottom: 10, 
    color: '#000000',
  },
  picker: {
    width: 250,
    height: 50,
    marginBottom: 20,
    color: '#000000',
  },
});
