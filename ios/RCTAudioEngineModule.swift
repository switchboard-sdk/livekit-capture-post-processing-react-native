//
//  RCTAudioEngineModule.swift
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//

import SwitchboardSDK
import SwitchboardVoicemod
import LiveKit


@objc(RCTAudioEngineModule)
class RCTAudioEngineModule : NSObject {

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
    do {
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
            try await room.localParticipant.setMicrophone(enabled: true)
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

    func audioProcessingInitialize(sampleRate: Int, channels: Int) {
      print("audioProcessingInitialize ")

      sampleRateHz = Double(sampleRate)
      numberOfChannels = channels
      
      buffer = UnsafeMutablePointer<UnsafeMutablePointer<Float>?>.allocate(capacity: numberOfChannels)
    }

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
