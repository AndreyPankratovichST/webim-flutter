#import "WebimPlugin.h"
#if __has_include(<webim/webim-Swift.h>)
#import <webim/webim-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "webim-Swift.h"
#endif

@implementation WebimPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWebimPlugin registerWithRegistrar:registrar];
}
@end
