package com.livekitcapturepostprocessing

import android.util.Log
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.synervoz.switchboard.sdk.audiograph.AudioBuffer
import com.synervoz.switchboard.sdk.audiograph.AudioData
import com.synervoz.switchboard.sdk.audiograph.AudioGraph
import com.synervoz.switchboard.sdk.audiographnodes.GainNode
import com.synervoz.switchboard.sdk.enums.AudioSampleFormat
import com.synervoz.switchboardvoicemod.audiographnodes.VoicemodNode
import io.livekit.android.AudioOptions
import io.livekit.android.LiveKit
import io.livekit.android.LiveKitOverrides
import io.livekit.android.audio.AudioProcessorInterface
import io.livekit.android.audio.AudioProcessorOptions
import io.livekit.android.events.RoomEvent
import io.livekit.android.events.collect
import io.livekit.android.room.Room
import kotlinx.coroutines.launch
import java.nio.ByteBuffer


class AudioEngineModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    var sampleRate = 0
    var numberOfChannels = 0
    val encoding = AudioSampleFormat.PCM_FLOAT32

    // Ensure maxNumberOfFrames is set to at least the maximum expected number of frames (numFrames) processed processAudio callback function.
    // usually numFrames = 480
    val maxNumberOfFrames = 960
    lateinit var inByteArray: ByteArray

    lateinit var inAudioData: AudioData
    lateinit var outAudioData: AudioData

    lateinit var inAudioBuffer: AudioBuffer
    lateinit var outAudioBuffer: AudioBuffer

    val audioGraph = AudioGraph()
    val voicemodNode = VoicemodNode()
    val normalizationGainNode = GainNode()
    val denormalizationGainNode = GainNode()

    lateinit var room: Room

    private val audioProcessorOptions = AudioProcessorOptions(
        capturePostProcessor = object : AudioProcessorInterface {
            override fun isEnabled(): Boolean {
                return true
            }

            override fun getName(): String {
                return "Switchboard SDK"
            }

            override fun initializeAudioProcessing(sampleRateHz: Int, numChannels: Int) {
                initAudioBuffers(sampleRateHz, numChannels)
            }

            override fun resetAudioProcessing(newRate: Int) {
                onSamplerateChanged(newRate)
            }

            override fun processAudio(numBands: Int, numFrames: Int, buffer: ByteBuffer) {
                processAudioInternal(numBands, numFrames, buffer)
            }
        }
    )

    init {
        Log.d(TAG, "init")
    }

    override fun getName(): String {
        return TAG
    }

    @ReactMethod
    fun init() {
        room = LiveKit.create(
            appContext = reactApplicationContext,
            overrides = LiveKitOverrides(
                audioOptions = AudioOptions(audioProcessorOptions = audioProcessorOptions),
            ),
        )

        room.audioProcessingController.setBypassForCapturePostProcessing(true)

        audioGraph.addNode(normalizationGainNode)
        audioGraph.addNode(denormalizationGainNode)
        audioGraph.addNode(voicemodNode)

        audioGraph.connect(audioGraph.inputNode, normalizationGainNode)
        audioGraph.connect(normalizationGainNode, voicemodNode)
        audioGraph.connect(voicemodNode, denormalizationGainNode)
        audioGraph.connect(denormalizationGainNode, audioGraph.outputNode)

        val normalizationFactor = 32768f
        normalizationGainNode.gain = 1f / normalizationFactor
        denormalizationGainNode.gain = normalizationFactor

        audioGraph.start()
    }

    @ReactMethod
    fun connectToRoom(wsURL: String, token: String) {
        currentActivity?.let { activity ->
            if (activity is LifecycleOwner) {
                activity.lifecycleScope.launch {
                    launch {
                        room.events.collect { event ->
                            when (event) {
                                is RoomEvent.TrackSubscribed -> onTrackSubscribed(event)
                                else -> {}
                            }
                        }
                    }

                    room.connect(wsURL, token)

                    val localParticipant = room.localParticipant
                    localParticipant.setMicrophoneEnabled(true)
                    localParticipant.setCameraEnabled(false)
                }
            }
        }
    }

    @ReactMethod
    fun enableVoicemod(enable: Boolean) {
        Log.d(TAG, "enableVoicemod: $enable")
        room.audioProcessingController.setBypassForCapturePostProcessing(!enable)
    }

    @ReactMethod
    fun loadVoice(voiceName: String) {
        voicemodNode.loadVoice(voiceName)
    }

    private fun onTrackSubscribed(event: RoomEvent.TrackSubscribed) {
        val subscriberName = event.participant.identity?.value ?: "Unknown"
        Log.d(TAG, "onTrackSubscribed: $subscriberName")
        reactApplicationContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("onTrackSubscribed", subscriberName)
    }

    private fun processAudioInternal(numBands: Int, numFrames: Int, buffer: ByteBuffer) {
        inAudioBuffer.setNumberOfFrames(numFrames)
        outAudioBuffer.setNumberOfFrames(numFrames)

        val numBytes = numFrames * numberOfChannels * encoding.bytesPerSample

        val currentPos = buffer.position()

        buffer.get(inByteArray, 0, numBytes)

        inAudioBuffer.copyFromByteArray(
            inByteArray,
            numBytes,
            encoding
        )

        audioGraph.processBuffer(inAudioBuffer, outAudioBuffer)

        buffer.position(currentPos)

        buffer.put(
            outAudioBuffer.getByteArray(encoding),
            0,
            numBytes
        )

    }

    private fun initAudioBuffers(sampleRateHz: Int, numChannels: Int) {

        if (!::inAudioData.isInitialized || numChannels != numberOfChannels) {
            // if numberOfChannels changed we new to create new instances
            if (::inAudioData.isInitialized) {
                inAudioData.close()
                outAudioData.close()
                inAudioBuffer.close()
                outAudioBuffer.close()
            }
            inByteArray = ByteArray(maxNumberOfFrames * numChannels * encoding.bytesPerSample)

            inAudioData = AudioData(numChannels, maxNumberOfFrames)
            outAudioData = AudioData(numChannels, maxNumberOfFrames)

            inAudioBuffer = AudioBuffer(
                numChannels,
                maxNumberOfFrames,
                false,
                sampleRateHz,
                inAudioData
            )
            outAudioBuffer = AudioBuffer(
                numChannels,
                maxNumberOfFrames,
                false,
                sampleRateHz,
                outAudioData
            )
        } else if (sampleRateHz != sampleRate) {
            inAudioBuffer.setSampleRate(sampleRateHz)
            outAudioBuffer.setSampleRate(sampleRateHz)
        }

        sampleRate = sampleRateHz
        numberOfChannels = numChannels
    }

    fun onSamplerateChanged(newRate: Int) {
        if (newRate != sampleRate) {
            inAudioBuffer.setSampleRate(newRate)
            outAudioBuffer.setSampleRate(newRate)
        }

        sampleRate = newRate
    }

    @ReactMethod
    fun releaseResources() {
        audioGraph.close()
        inAudioData.close()
        outAudioData.close()
        inAudioBuffer.close()
        outAudioBuffer.close()
        voicemodNode.close()
    }

    companion object {
        const val TAG = "AudioEngineModule"
    }
}