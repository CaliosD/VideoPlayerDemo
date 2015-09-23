//
//  DPlayerViewController.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DPlayerView.h"

@interface DPlayerViewController : UIViewController

@property (nonatomic, strong) AVPlayer     *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSURL        *url;
@property (nonatomic, strong) DPlayerView  *playerView;
@property (nonatomic, assign) BOOL         isFullScreen;


- (id)initWithFrame:(CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (void)navigationButtonClick:(NSInteger)index;

@end
