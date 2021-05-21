//
//  SMAMoPubSmaatoRewardedVideoAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 13.11.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <SmaatoSDKRewardedAds/SmaatoSDKRewardedAds.h>
#import "SMAMoPubSmaatoRewardedVideoAdapter.h"
#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

static NSString *const kSMAMoPubVideoRewardedAdapterServerAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAMoPubVideoRewardedAdapterLocalCreativeIdKey = @"smaato_ubid";
static NSString *const kSMAMoPubVideoRewardedVideoAdapterVersion = @"5.17.0.0";

@interface SMAMoPubSmaatoRewardedVideoAdapter () <SMARewardedInterstitialDelegate>
@property (nonatomic) SMARewardedInterstitial *rewardedAd;
@property (nonatomic, copy) NSString *adSpaceId;
@end

@implementation SMAMoPubSmaatoRewardedVideoAdapter

+ (NSString *)version
{
    return kSMAMoPubVideoRewardedVideoAdapterVersion;
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // Extract ad space information
    self.adSpaceId = [self fetchValueForKey:kSMAMoPubVideoRewardedAdapterServerAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:self.adSpaceId]) {
        return;
    }

    // Unified Bidding support (if available)
    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];
    adRequestParams.ubUniqueId = [self fetchValueForKey:kSMAMoPubVideoRewardedAdapterLocalCreativeIdKey fromEventInfo:self.localExtras];

    // Passing mediation information
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAMoPubVideoRewardedVideoAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [[MoPub sharedInstance] version];

    // Load ad
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:[self smaatoMediationNetworkName] dspCreativeId:nil dspName:nil],
                 [self getAdNetworkId]);
    [SmaatoSDK loadRewardedInterstitialForAdSpaceId:self.adSpaceId delegate:self requestParams:adRequestParams];
}

- (NSString *)fetchValueForKey:(NSString *)definedKey fromEventInfo:(NSDictionary *)info
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

- (BOOL)checkCredentialsWithAdSpaceId:(NSString *)adSpaceId
{
    if (adSpaceId) {
        return YES;
    }

    NSString *errorMessage = @"AdSpaceId can not be extracted. Please check your configuration on MoPub dashboard.";
    MPLogInfo(@"[SmaatoSDK] [Error] %@: %@", [self smaatoMediationNetworkName], errorMessage);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:didFailToLoadAdWithError:)]) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeInvalidRequest userInfo:userInfo];

        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
    }

    return NO;
}

- (void)presentAdFromViewController:(UIViewController *)viewController
{
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if (self.rewardedAd.availableForPresentation) {
        [self.rewardedAd showFromViewController:viewController];
    } else {
        NSString *errorMessage = @"Rewarded Ad is not available for presentation";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);
        if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:didFailToShowAdWithError:)]) {
            [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
        }
    }
}

- (BOOL)hasAdAvailable
{
    return self.rewardedAd.availableForPresentation;
}

- (NSString *)getAdNetworkId
{
    return self.adSpaceId;
}

- (NSString *)smaatoMediationNetworkName
{
    return NSStringFromClass([self class]);
}

- (BOOL)isRewardExpected
{
    return YES;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return YES;
}

#pragma mark - SMARewardedInterstitialDelegate

- (void)rewardedInterstitialDidFail:(SMARewardedInterstitial *)rewardedInterstitial withError:(NSError *)error
{
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:didFailToLoadAdWithError:)]) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)rewardedInterstitialDidLoad:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    self.rewardedAd = rewardedInterstitial;
    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidLoadAd:)]) {
        [self.delegate fullscreenAdAdapterDidLoadAd:self];
    }
}

- (void)rewardedInterstitialDidReward:(SMARewardedInterstitial *)rewardedInterstitial
{
    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:willRewardUser:)]) {
        // Smaato doesn't retrieve exact reward (currency and amount) after video ad completion, due to this reason
        // publisher should supply with mandatory rewardedVideoAdShouldReward() function calling himself.
        // Publisher has to add new reward in Mopub Dashboard for given RewardedVideo adUnitId and this reward will be forwarded to
        // publusher app, after rewarded video completion
        [self.delegate fullscreenAdAdapter:self willRewardUser:[MPReward unspecifiedReward]];
    }
}

- (void)rewardedInterstitialDidTTLExpire:(SMARewardedInterstitial *)rewardedInterstitial
{
    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidExpire:)]) {
        [self.delegate fullscreenAdAdapterDidExpire:self];
    }
}

- (void)rewardedInterstitialWillAppear:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdWillAppear:)]) {
        [self.delegate fullscreenAdAdapterAdWillAppear:self];
    }
}

- (void)rewardedInterstitialDidAppear:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidAppear:)]) {
        [self.delegate fullscreenAdAdapterAdDidAppear:self];
    }
}

- (void)rewardedInterstitialWillDisappear:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdWillDisappear:)]) {
        [self.delegate fullscreenAdAdapterAdWillDisappear:self];
    }
}

- (void)rewardedInterstitialDidDisappear:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidDisappear:)]) {
        [self.delegate fullscreenAdAdapterAdDidDisappear:self];
    }

    //    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidDismiss:)]) {
    //        [self.delegate fullscreenAdAdapterAdDidDismiss:self];
    //    }
}

- (void)rewardedInterstitialDidStart:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);
    // No corresponding delegate method from MoPub SDK available.
}

- (void)rewardedInterstitialDidClick:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adTappedForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidReceiveTap:)]) {
        [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    }
}

- (void)rewardedInterstitialWillLeaveApplication:(SMARewardedInterstitial *)rewardedInterstitial
{
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterWillLeaveApplication:)]) {
        [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
    }
}

@synthesize hasAdAvailable;

@end
