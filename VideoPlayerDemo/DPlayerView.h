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

/**
 *  Actions
 */
- (void)scrubberDidBegin;
- (void)scrubberValueChangedWithSeekTime:(float)seekTime isSlider:(BOOL)isSlider;
- (void)scrubberDidEnd;
- (void)playButtonPressed;
- (void)pauseButtonPressed;

@optional
- (void)doneButtonPressed;
- (void)nextButtonPressed;
- (void)captionButtonPressed;
- (void)fullscreenButtonPressed:(BOOL)isPortrait;

/**
 *  Touches
 */
- (float)updateMBProgressWithCurrent:(float)current andDelta:(float)delta;

@end

@interface DPlayerView : UIView

@property (nonatomic, strong) DPlayerLayerView        *playerLayerView;
@property (nonatomic, strong) UISlider                *scrubber;
@property (nonatomic, strong) UIProgressView          *loadProgress;
@property (nonatomic, strong) UIButton                *playButton;
@property (nonatomic, strong) UIButton                *nextButton;
@property (nonatomic, strong) UILabel                 *currentTimeLabel;
@property (nonatomic, strong) UILabel                 *totalTimeLabel;
@property (nonatomic, strong) UIButton                *captionButton;
@property (nonatomic, strong) UIButton                *fullscreenButton;


@property (nonatomic, strong) MBProgressHUD           *mbProgress;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) id<DPlayerViewDelegate    > delegate;

@end
