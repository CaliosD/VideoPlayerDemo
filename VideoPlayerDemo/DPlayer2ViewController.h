//
//  DPlayer2ViewController.h
//  VideoPlayerDemo
//
//  Created by Calios on 9/22/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DPlayerView.h"

@interface DPlayer2ViewController : UIViewController

@property (nonatomic, strong, setter = setPlayer:, getter=player) AVPlayer     *mPlayer;
@property (nonatomic, strong) AVPlayerItem *mPlayerItem;
@property (nonatomic, strong) NSURL        *mURL;
@property (nonatomic, strong) DPlayerView  *playerView;
@property (nonatomic, assign) BOOL         isFullScreen;
@property (nonatomic, assign) BOOL         shouldCancelLoading;

- (id)initWithFrame:(CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (void)setURL:(NSURL *)URL;

@end
