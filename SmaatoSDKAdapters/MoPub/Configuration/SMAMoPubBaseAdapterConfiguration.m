//
//  SMAMoPubBaseAdapterConfiguration.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 18/06/2019.
//  Copyright © 2019 Smaato. All rights reserved.
//

#import <SmaatoSDKCore/SmaatoSDK.h>
#import "SMAMoPubBaseAdapterConfiguration.h"

static NSString *const kSMAAdNetworkName = @"smaato";
static NSString *const kSMAMoPubAdapterMinorVersion = @"0";

static NSString *const kSMAMoPubConfigurationPublisherId = @"publisherId";
static NSString *const kSMAMoPubConfigurationHttpsOnly = @"httpsOnly";
static NSString *const kSMAMoPubConfigurationLogLevel = @"logLevel";
static NSString *const kSMAMoPubConfigurationLoggingDisabled = @"loggingDisabled";
static NSString *const kSMAMoPubConfigurationMaxAdContentRating = @"maxAdContentRating";

@implementation SMAMoPubBaseAdapterConfiguration

- (NSString *)adapterVersion
{
    return [NSString stringWithFormat:@"%@.%@", [self networkSdkVersion], kSMAMoPubAdapterMinorVersion];
}

- (NSString *)biddingToken
{
    return nil;
}

- (NSString *)moPubNetworkName
{
    return kSMAAdNetworkName;
}

- (NSString *)networkSdkVersion
{
    return [SmaatoSDK sdkVersion];
}

+ (void)updateInitializationParameters:(NSDictionary *)parameters
{
    [super setCachedInitializationParameters:parameters];
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *)configuration complete:(void (^)(NSError *_Nullable))complete
{
    NSString *publisherId = [self fetchValueForKey:kSMAMoPubConfigurationPublisherId from:configuration];
    if (publisherId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:@"'%@' is not available for SDK initialization via MoPub SDK. Ignore this "
                                                            @"message if you have already initialized Smaato SDK in your application code.",
                                                            kSMAMoPubConfigurationPublisherId];
        MPLogInfo(@"[SmaatoSDK] [Warning] %@: %@", NSStringFromClass(self.class), errorMessage);

        if (complete != nil) {
            complete(nil);
        }
        return;
    }

    SMAConfiguration *config = [[SMAConfiguration alloc] initWithPublisherId:publisherId];
    config.httpsOnly = [[self fetchValueForKey:kSMAMoPubConfigurationHttpsOnly from:configuration] boolValue];
    config.logLevel = [[self fetchValueForKey:kSMAMoPubConfigurationLogLevel from:configuration] intValue];
    config.loggingDisabled = [[self fetchValueForKey:kSMAMoPubConfigurationLoggingDisabled from:configuration] boolValue];
    config.maxAdContentRating = [[self fetchValueForKey:kSMAMoPubConfigurationMaxAdContentRating from:configuration] intValue];

    [SmaatoSDK initSDKWithConfig:config];

    if (complete != nil) {
        complete(nil);
    }
}

- (id)fetchValueForKey:(NSString *)definedKey from:(NSDictionary *)info
{
    __block NSString *value;
    [info enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([definedKey caseInsensitiveCompare:key] == NSOrderedSame) {
            value = obj;
            *stop = YES;
        }
    }];
    return value;
}

@end
