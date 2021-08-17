//
//  SMAMoPubSmaatoInterstitialAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 13.11.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <SmaatoSDKInterstitial/SmaatoSDKInterstitial.h>
#import "SMAMoPubSmaatoInterstitialAdapter.h"
#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

static NSString *const kSMAMoPubInterstitialAdapterServerAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAMoPubInterstitialAdapterLocalCreativeIdKey = @"smaato_ubid";
static NSString *const kSMAMoPubInterstitialAdapterVersion = @"5.18.0.0";

@interface SMAMoPubSmaatoInterstitialAdapter () <SMAInterstitialDelegate>
@property (nonatomic) SMAInterstitial *interstitial;
@property (nonatomic, copy) NSString *adSpaceId;
@end

@implementation SMAMoPubSmaatoInterstitialAdapter

+ (NSString *)version
{
    return kSMAMoPubInterstitialAdapterVersion;
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // Extract ad space information
    self.adSpaceId = [self fetchValueForKey:kSMAMoPubInterstitialAdapterServerAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:self.adSpaceId]) {
        return;
    }

    // Unified Bidding support (if available)
    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];
    adRequestParams.ubUniqueId = [self fetchValueForKey:kSMAMoPubInterstitialAdapterLocalCreativeIdKey fromEventInfo:self.localExtras];

    // Passing mediation information
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAMoPubInterstitialAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [[MoPub sharedInstance] version];

    // Load ad
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:[self smaatoMediationNetworkName] dspCreativeId:nil dspName:nil],
                 [self getAdNetworkId]);
    [SmaatoSDK loadInterstitialForAdSpaceId:self.adSpaceId delegate:self requestParams:adRequestParams];
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

    if (self.interstitial.availableForPresentation) {
        [self.interstitial showFromViewController:viewController];
    } else {
        NSString *errorMessage = @"Interstitial Ad is not available for presentation";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

        if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:didFailToShowAdWithError:)]) {
            [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
        }
    }
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
    return NO;
}

- (BOOL)hasAdAvailable
{
    return self.interstitial.availableForPresentation;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return YES;
}

#pragma mark - SMAInterstitialDelegate

- (void)interstitialDidLoad:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    self.interstitial = interstitial;
    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidLoadAd:)]) {
        [self.delegate fullscreenAdAdapterDidLoadAd:self];
    }
}

- (void)interstitial:(SMAInterstitial *)interstitial didFailWithError:(NSError *)error
{
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapter:didFailToLoadAdWithError:)]) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)interstitialDidTTLExpire:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidExpire:)]) {
        [self.delegate fullscreenAdAdapterDidExpire:self];
    }
}

- (void)interstitialWillAppear:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdWillAppear:)]) {
        [self.delegate fullscreenAdAdapterAdWillAppear:self];
    }
}

- (void)interstitialDidAppear:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidAppear:)]) {
        [self.delegate fullscreenAdAdapterAdDidAppear:self];
    }
}

- (void)interstitialWillDisappear:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdWillDisappear:)]) {
        [self.delegate fullscreenAdAdapterAdWillDisappear:self];
    }
}

- (void)interstitialDidDisappear:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidDisappear:)]) {
        [self.delegate fullscreenAdAdapterAdDidDisappear:self];
    }

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterAdDidDismiss:)]) {
        [self.delegate fullscreenAdAdapterAdDidDismiss:self];
    }
}

- (void)interstitialDidClick:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adTappedForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterDidReceiveTap:)]) {
        [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    }
}

- (void)interstitialWillLeaveApplication:(SMAInterstitial *)interstitial
{
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(fullscreenAdAdapterWillLeaveApplication:)]) {
        [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
    }
}

@synthesize hasAdAvailable;

@end
