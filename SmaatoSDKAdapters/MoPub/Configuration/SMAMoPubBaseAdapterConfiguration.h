//
//  SMAMoPubBaseAdapterConfiguration.h
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 18/06/2019.
//  Copyright © 2019 Smaato. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#elif __has_include(<mopub-ios-sdk/MoPub.h>)
#import <mopub-ios-sdk/MoPub.h>
#else
#import "MoPub.h"
#endif

@interface SMAMoPubBaseAdapterConfiguration : MPBaseAdapterConfiguration

@property (nonatomic, copy, readonly) NSString *_Nonnull adapterVersion;
@property (nonatomic, copy, readonly) NSString *_Nullable biddingToken;
@property (nonatomic, copy, readonly) NSString *_Nonnull moPubNetworkName;
@property (nonatomic, copy, readonly) NSString *_Nonnull networkSdkVersion;

+ (void)updateInitializationParameters:(NSDictionary *_Nonnull)parameters;

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *_Nullable)configuration
                                  complete:(void (^_Nullable)(NSError *_Nullable))complete;

@end
