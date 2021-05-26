//
//  SMAMoPubSmaatoBannerAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 29.10.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <SmaatoSDKBanner/SmaatoSDKBanner.h>
#import "SMAMoPubSmaatoBannerAdapter.h"
#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

static NSString *const kSMAMoPubBannerAdapterServerAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAMoPubBannerAdapterLocalCreativeIdKey = @"smaato_ubid";
static NSString *const kSMAMoPubBannerAdapterVersion = @"5.16.1.0";

@interface SMAMoPubSmaatoBannerAdapter () <SMABannerViewDelegate>
@property (nonatomic) SMABannerView *bannerView;
@property (nonatomic, copy) NSString *adSpaceId;
@end

@implementation SMAMoPubSmaatoBannerAdapter

+ (NSString *)version
{
    return kSMAMoPubBannerAdapterVersion;
}

- (void)requestAdWithSize:(CGSize)size adapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // Convert ad size format
    SMABannerAdSize convertedAdSize = [self SMABannerAdSizeFromRequestedSize:size];

    // Extract ad space information
    self.adSpaceId = [self fetchValueForKey:kSMAMoPubBannerAdapterServerAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:self.adSpaceId]) {
        return;
    }

    // Create and configure ad view object
    self.bannerView = [[SMABannerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    self.bannerView.delegate = self;
    self.bannerView.autoreloadInterval = kSMABannerAutoreloadIntervalDisabled;

    // Unified Bidding support (if available)
    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];
    adRequestParams.ubUniqueId = [self fetchValueForKey:kSMAMoPubBannerAdapterLocalCreativeIdKey fromEventInfo:self.localExtras];

    // Passing mediation information
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAMoPubBannerAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [[MoPub sharedInstance] version];

    // Load ad
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:[self smaatoMediationNetworkName] dspCreativeId:nil dspName:nil],
                 [self getAdNetworkId]);
    [self.bannerView loadWithAdSpaceId:self.adSpaceId adSize:convertedAdSize requestParams:adRequestParams];
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

- (SMABannerAdSize)SMABannerAdSizeFromRequestedSize:(CGSize)requestedSize
{
    if ((int)(requestedSize.height) >= 600) {
        return kSMABannerAdSizeSkyscraper_120x600;
    } else if ((int)(requestedSize.height) >= 250) {
        return kSMABannerAdSizeMediumRectangle_300x250;
    } else if ((int)(requestedSize.height) >= 90) {
        return kSMABannerAdSizeLeaderboard_728x90;
    } else {
        return kSMABannerAdSizeXXLarge_320x50;
    }
}

- (BOOL)checkCredentialsWithAdSpaceId:(NSString *)adSpaceId
{
    if (adSpaceId) {
        return YES;
    }

    NSString *errorMessage = @"AdSpaceId can not be extracted. Please check your configuration on MoPub dashboard.";
    MPLogInfo(@"[SmaatoSDK] [Error] %@: %@", [self smaatoMediationNetworkName], errorMessage);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didFailToLoadAdWithError:)]) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeInvalidRequest userInfo:userInfo];

        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
    }

    return NO;
}

- (NSString *)getAdNetworkId
{
    return self.adSpaceId;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

- (NSString *)smaatoMediationNetworkName
{
    return NSStringFromClass([self class]);
}

#pragma mark - SMABannerViewDelegate

- (UIViewController *)presentingViewControllerForBannerView:(SMABannerView *)bannerView
{
    return [self.delegate inlineAdAdapterViewControllerForPresentingModalView:self];
}

- (void)bannerViewDidLoad:(SMABannerView *)bannerView
{
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didLoadAdWithAdView:)]) {
        [self.delegate inlineAdAdapter:self didLoadAdWithAdView:bannerView];
    }
}

- (void)bannerViewDidClick:(SMABannerView *)bannerView
{
    MPLogAdEvent([MPLogEvent adTappedForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterDidTrackClick:)]) {
        [self.delegate inlineAdAdapterDidTrackClick:self];
    }
}

- (void)bannerView:(SMABannerView *)bannerView didFailWithError:(NSError *)error
{
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didFailToLoadAdWithError:)]) {
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)bannerViewWillPresentModalContent:(SMABannerView *)bannerView
{
    MPLogAdEvent([MPLogEvent adWillPresentModalForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterWillBeginUserAction:)]) {
        [self.delegate inlineAdAdapterWillBeginUserAction:self];
    }
}

- (void)bannerViewDidPresentModalContent:(SMABannerView *)bannerView
{
    // No corresponding delegate method from MoPub SDK available.
}

- (void)bannerViewDidDismissModalContent:(SMABannerView *)bannerView
{
    MPLogAdEvent([MPLogEvent adDidDismissModalForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterDidEndUserAction:)]) {
        [self.delegate inlineAdAdapterDidEndUserAction:self];
    }
}

- (void)bannerWillLeaveApplicationFromAd:(SMABannerView *)bannerView
{
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterWillLeaveApplication:)]) {
        [self.delegate inlineAdAdapterWillLeaveApplication:self];
    }
}

- (void)bannerViewDidTTLExpire:(SMABannerView *)bannerView
{
    NSString *errorMessage = @"Banner TTL has expired.";
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
    NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didFailToLoadAdWithError:)]) {
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)bannerViewDidImpress:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterDidTrackImpression:)]) {
        [self.delegate inlineAdAdapterDidTrackImpression:self];
    }
}
@end
