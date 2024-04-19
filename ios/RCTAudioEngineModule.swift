//
//  RCTAudioEngineModule.swift
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//

import SwitchboardSDK

@objc(RCTAudioEngineModule)
class RCTAudioEngineModule : NSObject {

  let audioEngine = SBAudioEngine()
  let audioGraph = SBAudioGraph()
  let sineGeneratorNode = SBSineGeneratorNode()

  override init() {
    super.init()

  }
  
  @objc
  func initSDK() {
    audioGraph.addNode(sineGeneratorNode)
    audioGraph.connect(sineGeneratorNode, to: audioGraph.outputNode)
    start()
  }
  
  @objc(connectToRoom:token:)
  func connectToRoom(wsURL: String, token: String) {
      print("Connecting to room with URL \(wsURL) and token \(token)")

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
    audioEngine.start(audioGraph)
  }

  func stop() {
    audioEngine.stop()
  }



  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
