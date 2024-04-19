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

  override init() {
    super.init()

  }
  
  @objc
  func initSDK() {
//    start()
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
    } catch {
      print("could not set audio session category")
    }
  }
  
  @objc(connectToRoom:token:)
  func connectToRoom(wsURL: String, token: String) {
    print("Connecting to room with URL \(wsURL) and token \(token)")
    Task {
        do {
            try await room.connect(url: wsURL, token: token)
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
  }  
  

  func start() {
//    audioEngine.start(audioGraph)
  }

  func stop() {
//    audioEngine.stop()
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
