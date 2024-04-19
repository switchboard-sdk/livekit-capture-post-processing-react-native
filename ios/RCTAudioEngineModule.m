//
//  RCTAudioEngineModule.m
//  LiveKitCapturePostProcessing
//
//  Created by Banto Balazs on 10/04/2024.
//


#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RCTAudioEngineModule, NSObject);

RCT_EXTERN_METHOD(initSDK)

RCT_EXTERN_METHOD(connectToRoom:(NSString *)wsURL token:(NSString *)token)

RCT_EXTERN_METHOD(loadVoice:(NSString *)voiceName)

RCT_EXTERN_METHOD(enableVoicemod:(BOOL)enable)


@end
