//
//  SMAMoPubSmaatoRewardedVideoAdapter.h
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 13.11.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#elif __has_include(<mopub-ios-sdk/MoPub.h>)
#import <mopub-ios-sdk/MoPub.h>
#else
#import "MPFullscreenAdAdapter.h"
#import "MoPub.h"
#endif

@interface SMAMoPubSmaatoRewardedVideoAdapter : MPFullscreenAdAdapter <MPThirdPartyFullscreenAdAdapter>
@property (class, nonatomic, readonly) NSString *version;
@end
