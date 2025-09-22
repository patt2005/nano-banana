#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.nano.ai.banana.app";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "1" asset catalog image resource.
static NSString * const ACImageName1 AC_SWIFT_PRIVATE = @"1";

/// The "2" asset catalog image resource.
static NSString * const ACImageName2 AC_SWIFT_PRIVATE = @"2";

/// The "3" asset catalog image resource.
static NSString * const ACImageName3 AC_SWIFT_PRIVATE = @"3";

/// The "4" asset catalog image resource.
static NSString * const ACImageName4 AC_SWIFT_PRIVATE = @"4";

/// The "5" asset catalog image resource.
static NSString * const ACImageName5 AC_SWIFT_PRIVATE = @"5";

/// The "banana" asset catalog image resource.
static NSString * const ACImageNameBanana AC_SWIFT_PRIVATE = @"banana";

/// The "bubble-chat" asset catalog image resource.
static NSString * const ACImageNameBubbleChat AC_SWIFT_PRIVATE = @"bubble-chat";

/// The "icon" asset catalog image resource.
static NSString * const ACImageNameIcon AC_SWIFT_PRIVATE = @"icon";

/// The "pro plan" asset catalog image resource.
static NSString * const ACImageNameProPlan AC_SWIFT_PRIVATE = @"pro plan";

#undef AC_SWIFT_PRIVATE
