//
//  RCTAudioEngineModule.swift
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//

import SwitchboardSDK
import SwitchboardVoicemod
import LiveKit
import React


@objc(RCTAudioEngineModule)
class RCTAudioEngineModule : RCTEventEmitter {

  let audioGraph = SBAudioGraph()
  let voicemodNode = SBVoicemodNode()
  let normalizationGainNode = SBGainNode()
  let denormalizationGainNode = SBGainNode()
  
  lazy var room = Room(delegate: self)
  var audioProcessor: AudioCustomProcessingDelegate!

  override init() {
    super.init()
    audioProcessor = MyAudioProcessor(graph: audioGraph)
  }
  
  @objc
  func initSDK() {
      audioGraph.addNode(normalizationGainNode)
      audioGraph.addNode(denormalizationGainNode)
      audioGraph.addNode(voicemodNode)
      
      audioGraph.connect(audioGraph.inputNode, to: normalizationGainNode)
      audioGraph.connect(normalizationGainNode, to: voicemodNode)
      audioGraph.connect(voicemodNode, to: denormalizationGainNode)
      audioGraph.connect(denormalizationGainNode, to: audioGraph.outputNode)

      let normalizationFactor:Float = 32768
      normalizationGainNode.gain = 1 / normalizationFactor
      denormalizationGainNode.gain = normalizationFactor

      audioGraph.start()
  }
  
  @objc(connectToRoom:token:)
  func connectToRoom(wsURL: String, token: String) {
    print("Connecting to room with URL \(wsURL) and token \(token)")
    AudioManager.shared.capturePostProcessingDelegate = audioProcessor

    Task {
        do {
            try await room.connect(url: wsURL, token: token)
            try await room.localParticipant.setMicrophone(enabled: true)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setActive(true)
        } catch {
            print("Failed to connect: \(error)")
        }
    }
  }

  @objc(loadVoice:)
  func loadVoice(voiceName: String) {
    print("Loading voice: \(voiceName)")
    voicemodNode.loadVoice(voiceName)
  }

  @objc(enableVoicemod:)
  func enableVoicemod(enable: Bool) {
    print("Voice modulation enabled: \(enable)")
    (audioProcessor as? MyAudioProcessor)?.bypassCapturePostProcessing = !enable
  }

  @objc
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  override func supportedEvents() -> [String]! {
      return ["onTrackSubscribed"]
  }

  func emitEventToReactNative(eventName: String, withBody body: Any) {
      self.sendEvent(withName: eventName, body: body)
  }
}

extension RCTAudioEngineModule: RoomDelegate {

    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {

    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
      let subscriberName = participant.identity?.stringValue ?? "Unknown"
      print("onTrackSubscribed: \(subscriberName)")
      emitEventToReactNative(eventName: "onTrackSubscribed", withBody: subscriberName)
    }
}

class MyAudioProcessor: AudioCustomProcessingDelegate {
  var sampleRateHz: Double = 0.0
  var numberOfChannels: Int = 0
  var bypassCapturePostProcessing = true
  
  var inAudioBuffer: SBAudioBuffer?
  var outAudioBuffer: SBAudioBuffer?
  var buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?
  let audioGraph: SBAudioGraph
  
  init(graph: SBAudioGraph) {
      self.audioGraph = graph
  }
  
  func setBypassForCapturePostProcessing(bypass: Bool) {
    self.bypassCapturePostProcessing = bypass
  }

  // TODO: currently only works is mono, but it's not an issue since usually channels = 1 anyways
    func audioProcessingInitialize(sampleRate: Int, channels: Int) {
      print("audioProcessingInitialize ")

      sampleRateHz = Double(sampleRate)
      numberOfChannels = channels
      
      buffer = UnsafeMutablePointer<UnsafeMutablePointer<Float>?>.allocate(capacity: numberOfChannels)
    }
  
  // TODO: currently only works is mono, but it's not an issue since usually channels = 1 anyways
    func audioProcessingProcess(audioBuffer: LiveKit.LKAudioBuffer) {
      if (!self.bypassCapturePostProcessing) {
        assert(numberOfChannels == audioBuffer.channels)
        let frameCount = audioBuffer.frames
        
        buffer!.advanced(by: 0).pointee = audioBuffer.rawBuffer(for: 0)
        
        inAudioBuffer = SBAudioBuffer(numberOfChannels: uint(numberOfChannels), numberOfFrames: uint(frameCount), interleaved: false, sampleRate: uint(sampleRateHz), data: buffer)
        outAudioBuffer = SBAudioBuffer(numberOfChannels: uint(numberOfChannels), numberOfFrames: uint(frameCount), interleaved: false, sampleRate: uint(sampleRateHz), data: buffer)
        
        audioGraph.processBuffer(inAudioBuffer, outBuffer: outAudioBuffer)
      }
    }

    func audioProcessingRelease() {
      buffer?.deallocate()
    }
}
