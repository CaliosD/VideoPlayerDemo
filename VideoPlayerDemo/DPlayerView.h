//
//  DPlayerView.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPlayerLayerView.h"
#import <MBProgressHUD.h>

static void *CurrentTimeContext = &CurrentTimeContext;


@protocol DPlayerViewDelegate <NSObject>

- (void)doneButtonPressed;
- (void)scrubberValueChanged:(UISlider *)sender;
- (void)playButtonPressed;
- (void)pauseButtonPressed;
- (void)nextButtonPressed;
- (void)fullscreenButtonPressed;

@end

@interface DPlayerView : UIView

@property (nonatomic, strong) DPlayerLayerView *playerLayerView;
@property (nonatomic, strong) UISlider         *scrubber;
@property (nonatomic, strong) UIProgressView   *loadProgress;
@property (nonatomic, strong) UIButton         *playButton;
@property (nonatomic, strong) UIButton         *nextButton;
@property (nonatomic, strong) UILabel          *currentTimeLabel;
@property (nonatomic, strong) UILabel          *totalTimeLabel;

@property (nonatomic, strong) id<DPlayerViewDelegate> delegate;
@property (nonatomic, strong) NSString         *currentTime;
@property (nonatomic, strong) NSString         *totalTime;

@end
