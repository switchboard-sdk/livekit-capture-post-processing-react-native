//
//  RCTAudioEngineModule.swift
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//

import SwitchboardSDK

@objc(RCTAudioEngineModule)
class RCTAudioEngineModule : NSObject {

  lazy var audioEngine = SBAudioEngine()
  lazy var audioGraph = SBAudioGraph()
  lazy var sineGeneratorNode = SBSineGeneratorNode()

  override init() {
    super.init()
    SBSwitchboardSDK.initialize(withClientID: "clientID", clientSecret: "clientSecret")
  }
  
  @objc
  func initialize() {
    audioGraph.addNode(sineGeneratorNode)
    audioGraph.connect(sineGeneratorNode, to: audioGraph.outputNode)
    start()
  }

  @objc
  func start() {
    audioEngine.start(audioGraph)
  }

  @objc
  func stop() {
    audioEngine.stop()
  }

  @objc
  func setFrequency(_ newValue: Float) {
      sineGeneratorNode.frequency = newValue
  }

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
