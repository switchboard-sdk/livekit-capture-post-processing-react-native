 # Real-Time Voicemod Effects in LiveKit Rooms with SwitchboardSDK

 <a href="https://docs.switchboard.audio/" target="_blank">Find more info on the Switchboard SDK HERE</a>

<a href="https://youtu.be/HNWxEQmuF1k" target="_blank">YouTube Demo Video</a>

This project demonstrates how to apply Voicemod effects in real-time within a LiveKit room. It uses LiveKit’s AudioProcessingController capture post-processing interface and leverages the flexibility of SwitchboardSDK's audio graph approach to enable dynamic audio processing.

## Features
 - Real-time [`Voicemod Effects`](https://docs.switchboard.audio/docs/extensions/voicemod/): Apply dynamic voice effects during live sessions.
 - [`LiveKit`](https://livekit.io/) Integration: Utilize LiveKit for robust audio and video streaming.
 - [`SwitchboardSDK`](https://docs.switchboard.audio/): Leverage advanced audio processing capabilities with SwitchboardSDK.



## Android Setup

Before opening the project please run:

```
sh scripts/setup_android.sh
```

This will download the necessary libraries to build the project.

## Run Android App
```
npx react-native run-android
```

## Run iOS App
```
npx react-native run-ios
```
