
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif
#import <UIKit/UIKit.h>

@interface SMOSmImagebarcode : NSObject <RCTBridgeModule, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end
  
