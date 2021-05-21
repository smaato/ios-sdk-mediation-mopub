//
//  SMAMoPubSmaatoNativeCustomEvent.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 30.01.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import "SMAMoPubSmaatoNativeCustomEvent.h"
#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

@interface SMAMoPubSmaatoNativeCustomEvent ()

@property (nonatomic) NSDictionary *properties;
@property (nonatomic) NSURL *defaultActionURL;
@property (nonatomic) SMANativeAdRenderer *nativeAdRenderer;
@property (nonatomic) SMANativeAd *nativeAd;

@end

@implementation SMAMoPubSmaatoNativeCustomEvent

@synthesize delegate;

- (instancetype)initWithNativeAd:(SMANativeAd *)nativeAd adRenderer:(SMANativeAdRenderer *)nativeAdRenderer
{
    self = [super init];

    if (self) {
        self.nativeAd = nativeAd;
        self.nativeAdRenderer = nativeAdRenderer;
        self.properties = [self getDictionaryFromAssets:nativeAdRenderer.nativeAssets];
        self.defaultActionURL = nil;
    }

    return self;
}

- (NSDictionary *)getDictionaryFromAssets:(SMANativeAdAssets *)assets
{
    NSMutableDictionary *properties = [NSMutableDictionary new];
    [properties setValue:assets.title forKey:kAdTitleKey];
    [properties setValue:assets.mainText forKey:kAdTextKey];
    [properties setValue:assets.icon.url.absoluteString forKey:kAdIconImageKey];
    [properties setValue:assets.images.firstObject.url.absoluteString forKey:kAdMainImageKey];
    [properties setValue:assets.cta forKey:kAdCTATextKey];
    // [properties setValue:assets.sponsored forKey:??]  // Sponsored Text MoPub 5.11+
    [properties setValue:[NSNumber numberWithDouble:assets.rating] forKey:kAdStarRatingKey];
    return properties;
}

- (UIView *)privacyInformationIconView
{
    return self.nativeAdRenderer.privacyView;
}

- (BOOL)enableThirdPartyClickTracking
{
    return YES;
}

- (void)willAttachToView:(UIView *)view withAdContentViews:(NSArray *)adContentViews
{
    [self.nativeAdRenderer registerViewForImpression:view];
    [self.nativeAdRenderer registerViewsForClickAction:adContentViews];
}

#pragma mark - <SMANativeAdDelegate> methods

- (void)nativeAd:(SMANativeAd *)nativeAd didLoadWithAdRenderer:(SMANativeAdRenderer *)renderer
{
    // Method should be called before SMAMoPubSmaatoNativeCustomEvent instance creating
}

- (void)nativeAd:(SMANativeAd *)nativeAd didFailWithError:(NSError *)error
{
    // Method should be called instead of SMAMoPubSmaatoNativeCustomEvent instance creating
}

- (void)nativeAdDidTTLExpire:(SMANativeAd *)nativeAd
{
    // No corresponding delegate method from MoPub SDK available.
}

- (UIViewController *)presentingViewControllerForNativeAd:(SMANativeAd *)nativeAd
{
    return self.delegate.viewControllerForPresentingModalView;
}

- (void)nativeAdWillPresentModalContent:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(nativeAdWillPresentModalForAdapter:)]) {
        [self.delegate nativeAdWillPresentModalForAdapter:self];
    }
}

- (void)nativeAdDidPresentModalContent:(SMANativeAd *)nativeAd
{
    // No corresponding delegate method from MoPub SDK available.
}

- (void)nativeAdDidDismissModalContent:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(nativeAdDidDismissModalForAdapter:)]) {
        [self.delegate nativeAdDidDismissModalForAdapter:self];
    }
}

- (void)nativeAdWillLeaveApplicationFromAd:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(nativeAdWillLeaveApplicationFromAdapter:)]) {
        [self.delegate nativeAdWillLeaveApplicationFromAdapter:self];
    }
}

- (void)nativeAdDidImpress:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(nativeAdWillLogImpression:)]) {
        [self.delegate nativeAdWillLogImpression:self];
    }
}

- (void)nativeAdDidClick:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(nativeAdDidClick:)]) {
        [self.delegate nativeAdDidClick:self];
    }
}

@end
