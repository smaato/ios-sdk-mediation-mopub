//
//  SMAMoPubSmaatoNativeRendererSettings.h
//  SmaatoSDKMopubNativeAdapter
//
//  Created by Smaato Inc on 31.01.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
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
#import "MoPub.h"
#endif

@interface SMAMoPubSmaatoNativeRendererSettings : NSObject <MPNativeAdRendererSettings>
@property (nonatomic, readwrite, copy) MPNativeViewSizeHandler viewSizeHandler;
@end
