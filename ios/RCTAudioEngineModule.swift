//
//  RCTAudioEngineModule.swift
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//

import SwitchboardSDK
import LiveKit


@objc(RCTAudioEngineModule)
class RCTAudioEngineModule : NSObject {

//  let audioEngine = SBAudioEngine()
  let audioGraph = SBAudioGraph()
  
  lazy var room = Room(delegate: self)
  var audioProcessor: AudioCustomProcessingDelegate = MyAudioProcessor()

  override init() {
    super.init()

  }
  
  @objc
  func initSDK() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
    } catch {
      print("could not set audio session category")
    }
  }
  
  @objc(connectToRoom:token:)
  func connectToRoom(wsURL: String, token: String) {
    print("Connecting to room with URL \(wsURL) and token \(token)")
   AudioManager.shared.capturePostProcessingDelegate = audioProcessor

    Task {
        do {
            try await room.connect(url: wsURL, token: token)
//            AudioManager.shared.capturePostProcessingDelegate = audioProcessor
            try await room.localParticipant.setMicrophone(enabled: true)
        } catch {
            print("Failed to connect: \(error)")
        }
    }
  }

  @objc(loadVoice:)
  func loadVoice(voiceName: String) {
      print("Loading voice: \(voiceName)")
  }

  @objc(enableVoicemod:)
  func enableVoicemod(enable: Bool) {
    print("Voice modulation enabled: \(enable)")
    (audioProcessor as? MyAudioProcessor)?.bypassCapturePostProcessing = !enable
  }

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

extension RCTAudioEngineModule: RoomDelegate {

    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        guard let track = publication.track as? VideoTrack else {
            return
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        guard let track = publication.track as? VideoTrack else {
          return
        }
    }
}

class MyAudioProcessor: AudioCustomProcessingDelegate {
  var initSampleRate: Double = 0.0
  var initChannels: Int = 0
  var bypassCapturePostProcessing = true
  
  func setBypassForCapturePostProcessing(bypass: Bool) {
    self.bypassCapturePostProcessing = bypass
  }

    func audioProcessingInitialize(sampleRate: Int, channels: Int) {
      initSampleRate = Double(sampleRate)
      initChannels = channels
      print("audioProcessingInitialize ")

        // Initialization code here
    }

    func audioProcessingProcess(audioBuffer: LiveKit.LKAudioBuffer) {
      if (!self.bypassCapturePostProcessing) {
        let channelCount = audioBuffer.channels
        let frameCount = audioBuffer.frames

        for channel in 0..<channelCount {
            let samples = audioBuffer.rawBuffer(for: channel)
            for frame in 0..<frameCount {
                // Halve the volume by multiplying each sample by 0.5
                samples[frame] *= 0.1
            }
        }
      }
    }

    func audioProcessingRelease() {
        // Release resources if needed
    }
}
