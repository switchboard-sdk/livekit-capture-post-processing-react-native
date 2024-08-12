#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <SwitchboardSDK/SwitchboardSDK.h>
#import <SwitchboardVoicemod/SwitchboardVoicemod.h>
#import <SwitchboardRNNoise/SwitchboardRNNoise.h>



@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"LiveKitCapturePostProcessing";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  
  [SBSwitchboardSDK initializeWithAppID:@"YourClientIDHere" appSecret:@"YourClientSecretHere"];
  [SBVoicemodExtension initializeWithClientKey:@"YourVoicemodKey"];
  [SBRNNoiseExtension initialize];



  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}

- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
