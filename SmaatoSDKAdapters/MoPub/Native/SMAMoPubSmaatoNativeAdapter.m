//
//  SMAMoPubSmaatoNativeAdapter.m
//  SmaatoSDKMopubNativeAdapter
//
//  Created by Smaato Inc on 31.01.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <SmaatoSDKCore/SmaatoSDKCore.h>
#import <SmaatoSDKNative/SmaatoSDKNative.h>
#import "SMAMoPubSmaatoNativeAdapter.h"
#import "SMAMoPubSmaatoNativeCustomEvent.h"
#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

static NSString *const kSMAMoPubNativeAdapterServerAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAMoPubNativeAdapterLocalCreativeIdKey = @"smaato_ubid";
static NSString *const kSMAMoPubNativeAdapterVersion = @"5.16.1.0";

typedef void (^SMASMAMoPubMediatedNativeAdDeferredCallback)(MPNativeAd *mopudAd, id<MPNativeAdAdapter> smaatoAdapter);

@interface SMAMoPubSmaatoNativeAdapter () <SMANativeAdDelegate>
@property (nonatomic) SMANativeAd *nativeAd;
@property (nonatomic, copy) NSString *adSpaceId;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic) NSMutableArray<SMASMAMoPubMediatedNativeAdDeferredCallback> *deferredCallbacks;
@end

@implementation SMAMoPubSmaatoNativeAdapter

- (void)requestAdWithAdapterInfo:(NSDictionary *)info
{
    // MoPub document mentions this method to be implemented but it is not availble
    // inside the MoPub SDK yet. Adding this anyway incase MoPub realizes and updates the SDK in future.
    // If they update the document, this method will be removed from Smaato adapter from future.
    [self requestAdWithCustomEventInfo:info adMarkup:nil];
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // MoPub document mentions this method to be implemented but it is not availble
    // inside the MoPub SDK yet. Adding this anyway incase MoPub realizes and updates the SDK in future.
    // If they update the document, this method will be removed from Smaato adapter from future.
    [self requestAdWithCustomEventInfo:info adMarkup:adMarkup];
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info
{
    [self requestAdWithCustomEventInfo:info adMarkup:nil];
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    self.deferredCallbacks = [NSMutableArray new];

    // Extract ad space information
    self.adSpaceId = [self fetchValueForKey:kSMAMoPubNativeAdapterServerAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:self.adSpaceId]) {
        return;
    }

    // Create and configure ad object
    self.nativeAd = [[SMANativeAd alloc] init];
    self.nativeAd.delegate = self;

    // Unified Bidding support (if available)
    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];
    adRequestParams.ubUniqueId = [self fetchValueForKey:kSMAMoPubNativeAdapterLocalCreativeIdKey fromEventInfo:self.localExtras];

    // Passing mediation information
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAMoPubNativeAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [[MoPub sharedInstance] version];

    // Load ad
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:[self smaatoMediationNetworkName] dspCreativeId:nil dspName:nil],
                 [self getAdNetworkId]);

    SMANativeAdRequest *adRequest = [[SMANativeAdRequest alloc] initWithAdSpaceId:self.adSpaceId];
    adRequest.allowMultipleImages = NO;
    adRequest.returnUrlsForImageAssets = YES;
    [self.nativeAd loadWithAdRequest:adRequest requestParams:adRequestParams];
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

    if ([self.delegate respondsToSelector:@selector(nativeCustomEvent:didFailToLoadAdWithError:)]) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeInvalidRequest userInfo:userInfo];

        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
    }

    return NO;
}

+ (NSString *)version
{
    return kSMAMoPubNativeAdapterVersion;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

- (NSString *)getAdNetworkId
{
    return self.adSpaceId;
}

- (NSString *)smaatoMediationNetworkName
{
    return NSStringFromClass([self class]);
}

#pragma mark - SMANativeAdDelegate

- (void)nativeAd:(SMANativeAd *)nativeAd didLoadWithAdRenderer:(SMANativeAdRenderer *)renderer
{
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:[self smaatoMediationNetworkName]], [self getAdNetworkId]);

    SMAMoPubSmaatoNativeCustomEvent *adapter = [[SMAMoPubSmaatoNativeCustomEvent alloc] initWithNativeAd:self.nativeAd adRenderer:renderer];
    MPNativeAd *mopudAd = [[MPNativeAd alloc] initWithAdAdapter:adapter];

    NSMutableArray *imageURLs = [NSMutableArray array];
    [@[ kAdIconImageKey, kAdMainImageKey ] enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
        NSString *value = adapter.properties[name];
        if (value) {
            NSURL *url = [NSURL URLWithString:value];
            if (url) {
                [imageURLs addObject:url];
            }
        }
    }];

    __weak __typeof__(self) wSelf = self;
    [super precacheImagesWithURLs:imageURLs
                  completionBlock:^(NSArray *errors) {
                      __typeof__(self) sSelf = wSelf;
                      if (errors) {
                          NSError *error = MPNativeAdNSErrorForImageDownloadFailure();
                          MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[sSelf smaatoMediationNetworkName] error:error],
                                       [sSelf getAdNetworkId]);
                          [sSelf.delegate nativeCustomEvent:sSelf didFailToLoadAdWithError:error];
                      } else {
                          MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:[sSelf smaatoMediationNetworkName]], [sSelf getAdNetworkId]);
                          if ([sSelf.delegate respondsToSelector:@selector(nativeCustomEvent:didLoadAd:)]) {
                              [sSelf.delegate nativeCustomEvent:sSelf didLoadAd:mopudAd];
                          }
                          nativeAd.delegate = adapter;
                          sSelf.presentingViewController = [mopudAd.delegate viewControllerForPresentingModalView];
                          [sSelf callDeferredCallbacksWithMopubNativeAd:mopudAd adapter:adapter];
                      }
                  }];
}

- (void)nativeAd:(SMANativeAd *)nativeAd didFailWithError:(NSError *)error
{
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(nativeCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
    }
}

- (void)nativeAdDidImpress:(SMANativeAd *)nativeAd
{
    // This workaround helps to prevent ads impression analytics discrepancy issue between Smaato and Mopub, because
    //\c nativeAdDidImpress: method might be called before \c nativeAd:didLoadWithAdRenderer: method will be
    // able to call \c nativeCustomEvent:didLoadAd: callback and
    @synchronized(self.deferredCallbacks)
    {
        SMASMAMoPubMediatedNativeAdDeferredCallback callback = ^(MPNativeAd *mopudAd, id<MPNativeAdAdapter> smaatoAdapter) {
            if ([smaatoAdapter.delegate respondsToSelector:@selector(nativeAdWillLogImpression:)]) {
                [smaatoAdapter.delegate nativeAdWillLogImpression:smaatoAdapter];
            }
        };
        [self.deferredCallbacks addObject:callback];
    }
}

- (void)nativeAdDidClick:(SMANativeAd *)nativeAd
{
    // This workaround helps to prevent ads clicks analytics discrepancy issue between Smaato and Mopub, because
    //\c nativeAdDidClick: method might be called before \c nativeAd:didLoadWithAdRenderer: method will be
    // able to call \c nativeCustomEvent:didLoadAd: callback and
    @synchronized(self.deferredCallbacks)
    {
        SMASMAMoPubMediatedNativeAdDeferredCallback callback = ^(MPNativeAd *mopudAd, id<MPNativeAdAdapter> smaatoAdapter) {
            if ([smaatoAdapter.delegate respondsToSelector:@selector(nativeAdDidClick:)]) {
                [smaatoAdapter.delegate nativeAdDidClick:smaatoAdapter];
            }
        };
        [self.deferredCallbacks addObject:callback];
    }
}

- (void)nativeAdDidTTLExpire:(SMANativeAd *)nativeAd
{
    NSString *errorMessage = @"Native TTL has expired.";
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
    NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:[self smaatoMediationNetworkName] error:error], [self getAdNetworkId]);

    if ([self.delegate respondsToSelector:@selector(nativeCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
    }
}

- (UIViewController *)presentingViewControllerForNativeAd:(SMANativeAd *)nativeAd
{
    return self.presentingViewController;
}

#pragma mark - Private

- (void)callDeferredCallbacksWithMopubNativeAd:(MPNativeAd *)mopudAd adapter:(id<MPNativeAdAdapter>)smaatoAdapter
{
    @synchronized(self.deferredCallbacks)
    {
        if (mopudAd && smaatoAdapter) {
            for (SMASMAMoPubMediatedNativeAdDeferredCallback callback in self.deferredCallbacks) {
                callback(mopudAd, smaatoAdapter);
            }
            [self.deferredCallbacks removeAllObjects];
        }
    }
}

@end
