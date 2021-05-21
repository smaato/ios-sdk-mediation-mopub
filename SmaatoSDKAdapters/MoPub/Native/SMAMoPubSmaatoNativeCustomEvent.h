//
//  SMAMoPubSmaatoNativeCustomEvent.h
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 30.01.20.
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

#import <SmaatoSDKNative/SmaatoSDKNative.h>

@interface SMAMoPubSmaatoNativeCustomEvent : NSObject <MPNativeAdAdapter, SMANativeAdDelegate>

/**
 Unavailable.
 Use \c initWithNativeAd: to create instances of \c SMAMoPubSmaatoNativeCustomEvent class.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Designated initializer. Creates instance of \c SMAMoPubSmaatoNativeCustomEvent
 class with the provided \c SMANativeAdAssets .

 @param nativeAd The native ad renderer object that should be retained if there is an intention to receive the
                 callbacks about ad life cycle
 @param nativeAdRenderer The native ad renderer object
 @return The initialized \c SMAMoPubSmaatoNativeCustomEvent
 */
- (instancetype)initWithNativeAd:(SMANativeAd *)nativeAd adRenderer:(SMANativeAdRenderer *)nativeAdRenderer NS_DESIGNATED_INITIALIZER;

@end
