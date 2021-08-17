//
//  SMAMoPubSmaatoNativeAdRenderer.m
//  SmaatoSDKMopubNativeAdapter
//
//  Created by Smaato Inc on 31.01.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import "SMAMoPubSmaatoNativeAdRenderer.h"
#import "SMAMoPubSmaatoNativeAdapter.h"

@interface SMAMoPubSmaatoNativeAdRenderer ()

@property (nonatomic, readwrite, copy) MPNativeViewSizeHandler viewSizeHandler;
@property (nonatomic) id<MPNativeAdRendererSettings> rendererSettings;

@end

@implementation SMAMoPubSmaatoNativeAdRenderer

+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings
{
    MPNativeAdRendererConfiguration *config = [[MPNativeAdRendererConfiguration alloc] init];
    config.rendererClass = [SMAMoPubSmaatoNativeAdRenderer class];
    config.supportedCustomEvents = @[ NSStringFromClass([SMAMoPubSmaatoNativeAdapter class]) ];
    config.rendererSettings = rendererSettings;
    return config;
}

- (instancetype)initWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings
{
    self = [super init];

    if (self) {
        self.viewSizeHandler = rendererSettings.viewSizeHandler;
        self.rendererSettings = rendererSettings;
    }

    return self;
}

// TODO: Return a view that contains the rendered ad elements using the data contained in your adapter class. You should recreate the view
// each time this is called if possible.
- (UIView *)retrieveViewWithAdapter:(id<MPNativeAdAdapter>)adapter error:(NSError *__autoreleasing *)error
{
    /**
     Return a view that contains the rendered ad elements using the data contained in your adapter class. You should recreate the view each
    time this is called if possible.
    **/

    return [[UIView alloc] init];
}

@end
