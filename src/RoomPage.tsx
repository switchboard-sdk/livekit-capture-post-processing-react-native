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
        <Picker.Item label="Alice" value="alice" />
        <Picker.Item label="Alien" value="alien" />
        <Picker.Item label="Baby" value="baby" />
        <Picker.Item label="Belcher" value="belcher" />
        <Picker.Item label="Blocks" value="blocks" />
        <Picker.Item label="Bob" value="bob" />
        <Picker.Item label="Cartoon Man" value="cartoon-man" />
        <Picker.Item label="Cartoon Woman" value="cartoon-woman" />
        <Picker.Item label="Cave" value="cave" />
        <Picker.Item label="Dark" value="dark" />
        <Picker.Item label="Deep" value="deep" />
        <Picker.Item label="Fire Dragon" value="fire-dragon" />
        <Picker.Item label="Gas Mask" value="gas-mask" />
        <Picker.Item label="Genki" value="genki" />
        <Picker.Item label="Ghost" value="ghost" />
        <Picker.Item label="Magic Chords" value="magic-chords" />
        <Picker.Item label="Mothership" value="mothership" />
        <Picker.Item label="Mr. X" value="mr-x" />
        <Picker.Item label="Out of Range" value="out-of-range" />
        <Picker.Item label="Pilot" value="pilot" />
        <Picker.Item label="Radio Demon" value="radio-demon" />
        <Picker.Item label="Robot" value="robot" />
        <Picker.Item label="Runic Sorceress" value="runic-sorceress" />
        <Picker.Item label="Space Trooper" value="space-trooper" />
        <Picker.Item label="Speechifier" value="speechifier" />
        <Picker.Item label="The Billionhair" value="the-billionhair" />
        <Picker.Item label="The Demon" value="the-demon" />
        <Picker.Item label="The Narrator" value="the-narrator" />
        <Picker.Item label="Trailer Guy" value="trailer-guy" />
        <Picker.Item label="Trap Tune" value="trap-tune" />
        <Picker.Item label="Trauma Medic" value="trauma-medic" />
        <Picker.Item label="Uncle in Chief" value="uncle-in-chief" />
        <Picker.Item label="Voicelab" value="voicelab" />
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
