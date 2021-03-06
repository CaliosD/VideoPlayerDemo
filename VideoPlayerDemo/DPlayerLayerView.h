//
//  DPlayerLayerView.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DPlayerLayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

- (void)setVideoFillMode:(NSString *)fillMode;

@end
