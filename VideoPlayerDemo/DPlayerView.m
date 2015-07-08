//
//  DPlayerView.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayerView.h"
#import <MBProgressHUD.h>
#import <PureLayout.h>

#import "Constant.h"    // Set it as a changable property.



@interface DPlayerView ()

@property (nonatomic, strong) UIActivityIndicatorView      *activityIndicator;

@property (nonatomic, strong) UIView                       *topControlOverlay;
@property (nonatomic, strong) UILabel                      *titleLabel;
@property (nonatomic, strong) UIButton                     *doneButton;

@property (nonatomic, strong) UIView                       *bottomControlOverlay;
@property (nonatomic, strong) UIButton                     *fullscreenButton;
@property (nonatomic, strong) UIButton                     *captionButton;

@property (nonatomic, strong) UIView                       *middleControlOverLay;
@property (nonatomic, strong) UIButton                     *bigPlayButton;
@property (nonatomic, strong) UISlider                     *volumeSlider;

@property (nonatomic, assign) BOOL                         isControlsEnabled;
@property (nonatomic, assign) BOOL                         isControlsHidden;
@property (nonatomic, assign) BOOL                         isPlayButtonSelected;
@property (nonatomic, assign) CGPoint                      startPoint;
//@property (nonatomic, weak) id<VKVideoPlayerGestureDelegate> gestureDelegate;
@property (nonatomic, strong) MBProgressHUD                *mbProgress;


@end

@implementation DPlayerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initPlayerLayer];
        
        [self initTopControl];
        
        [self initMiddleControl];
        
        [self initBottomControl];
        
        [self.currentTime addObserver:self forKeyPath:@"currentTime" options:0 context:CurrentTimeContext];
    }
    return self;
}

- (void)layoutSubviews
{
    self.backgroundColor = [UIColor whiteColor];
    _isControlsEnabled = YES;
    _isControlsHidden = YES;

    [self setNeedsUpdateConstraints];
}

#pragma mark - Initialize

- (void)initPlayerLayer
{
    _playerLayerView = [DPlayerLayerView newAutoLayoutView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapPlayView)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [_playerLayerView addGestureRecognizer:tapGesture];
    [self addSubview:_playerLayerView];
    [_playerLayerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
}

- (void)initTopControl
{
    _topControlOverlay = [UIView newAutoLayoutView];
    _topControlOverlay.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.7];
    [self addSubview:_topControlOverlay];
 
    _doneButton = [UIButton newAutoLayoutView];
    [_doneButton setImage:[UIImage imageNamed:@"VKVideoPlayer_cross"] forState:UIControlStateNormal];
    [_doneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_topControlOverlay addSubview:_doneButton];
    
    _titleLabel = [UILabel newAutoLayoutView];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = @"Video Player Demo";
    [_topControlOverlay addSubview:_titleLabel];
}

- (void)initMiddleControl
{
//    _middleControlOverLay = [UIView newAutoLayoutView];
//    _middleControlOverLay.backgroundColor = [UIColor clearColor];
//    [self addSubview:_middleControlOverLay];
    
    _bigPlayButton = [UIButton newAutoLayoutView];
    [_bigPlayButton setImage:[UIImage imageNamed:@"VKVideoPlayer_pause_big"] forState:UIControlStateNormal];
    [_bigPlayButton setImage:[UIImage imageNamed:@"VKVideoPlayer_play_big"] forState:UIControlStateSelected];
    [_bigPlayButton addTarget:self action:@selector(playButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_bigPlayButton];
    
//    _volumeSlider = [UISlider newAutoLayoutView];
//    _volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
//    _volumeSlider.backgroundColor = [UIColor blueColor];
//    [_middleControlOverLay addSubview:_volumeSlider];
}

- (void)initBottomControl
{
    _bottomControlOverlay = [UIView newAutoLayoutView];
    _bottomControlOverlay.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.7];
    [self addSubview:_bottomControlOverlay];
    
    _loadProgress = [UIProgressView newAutoLayoutView];
    [_bottomControlOverlay addSubview:_loadProgress];
    
    _scrubber = [UISlider newAutoLayoutView];
    UIGraphicsBeginImageContextWithOptions((CGSize){1,1}, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_scrubber setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [_scrubber setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
    [_scrubber addTarget:self action:@selector(scrubberValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_bottomControlOverlay addSubview:_scrubber];
    
    _playButton = [UIButton newAutoLayoutView];
    [_playButton setImage:[UIImage imageNamed:@"VKVideoPlayer_pause"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"VKVideoPlayer_play"] forState:UIControlStateSelected];
    [_playButton addTarget:self action:@selector(playButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_bottomControlOverlay addSubview:_playButton];
    
    _nextButton = [UIButton newAutoLayoutView];
    [_nextButton setImage:[UIImage imageNamed:@"VKVideoPlayer_next"] forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_bottomControlOverlay addSubview:_nextButton];
    
    _currentTimeLabel = [UILabel newAutoLayoutView];
    _currentTimeLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.text = [NSString stringWithFormat:@"%@/",_currentTime];
    [_bottomControlOverlay addSubview:_currentTimeLabel];

    _totalTimeLabel = [UILabel newAutoLayoutView];
    _totalTimeLabel.textColor = [UIColor whiteColor];
    _totalTimeLabel.text = _totalTime;
    [_bottomControlOverlay addSubview:_totalTimeLabel];
    
    _captionButton = [UIButton newAutoLayoutView];
    [_captionButton setTitle:@"字幕" forState:UIControlStateNormal];
    [_captionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_bottomControlOverlay addSubview:_captionButton];
    
    _fullscreenButton = [UIButton newAutoLayoutView];
    [_fullscreenButton setImage:[UIImage imageNamed:@"VKVideoPlayer_zoom_in"] forState:UIControlStateNormal];
    [_fullscreenButton setImage:[UIImage imageNamed:@"VKVideoPlayer_zoom_out"] forState:UIControlStateSelected];
    [_fullscreenButton addTarget:self action:@selector(fullscreenButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_bottomControlOverlay addSubview:_fullscreenButton];
}

- (void)updateConstraints
{
    /**
     *  Top control
     */
    [_topControlOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [_topControlOverlay autoSetDimension:ALDimensionHeight toSize:kNavigationBarHeight relation:NSLayoutRelationEqual];
    
    [_doneButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_doneButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_doneButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [_doneButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:_doneButton];
    
    [_titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [_titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_doneButton];
    [_titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    /**
     *  Bottom control
     */
    [_bottomControlOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 64, 0) excludingEdge:ALEdgeTop];
    [_bottomControlOverlay autoSetDimension:ALDimensionHeight toSize:(kNavigationBarHeight + kStatusBarHeight)];
    
    [_loadProgress autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(10, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [_loadProgress autoSetDimension:ALDimensionHeight toSize:2];
    
    [_scrubber autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(-5, 0, 0, 0) excludingEdge:ALEdgeBottom];

    NSArray *views = @[_playButton,_nextButton,_currentTimeLabel,_totalTimeLabel];
    [@[_playButton,_nextButton] autoSetViewsDimensionsToSize:CGSizeMake(kNavigationBarHeight, kNavigationBarHeight)];
    [@[_currentTimeLabel,_totalTimeLabel] autoSetViewsDimensionsToSize:CGSizeMake(kNavigationBarHeight + kStatusBarHeight,kNavigationBarHeight)];
    [[views firstObject] autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    UIView *previousView = nil;
    for (UIView *v in views) {
        if (previousView) {
            [v autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:previousView];
            [v autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:previousView];
        }
        previousView = v;
    }
    [_playButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_playButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    NSArray *rview = @[_captionButton,_fullscreenButton];
    [rview autoSetViewsDimensionsToSize:CGSizeMake(kNavigationBarHeight, kNavigationBarHeight)];

    [_captionButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:_fullscreenButton];
    [_captionButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_fullscreenButton];
    [_fullscreenButton autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_fullscreenButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    /**
     *  Middle control
     */
//    [_middleControlOverLay autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topControlOverlay];
//    [_middleControlOverLay autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_bottomControlOverlay];
//    [_middleControlOverLay autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//    [_middleControlOverLay autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [_bigPlayButton autoSetDimensionsToSize:CGSizeMake(74, 74)];
    [_bigPlayButton autoCenterInSuperview];
    
//    [_volumeSlider autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(10, 10, 10, 0) excludingEdge:ALEdgeRight];
//    [_volumeSlider autoSetDimension:ALDimensionWidth toSize:10.0];
    
    [super updateConstraints];
}

#pragma mark Actions

- (void)doneButtonPressed
{
    [self.delegate doneButtonPressed];
}

- (void)scrubberValueChanged:(UISlider *)sender
{
    [self.delegate scrubberValueChanged:sender];
}

- (void)playButtonPressed
{
    if (_playButton.selected) {
        [self.delegate playButtonPressed];
        self.isPlayButtonSelected = NO;
    }else{
        [self.delegate pauseButtonPressed];
        self.isPlayButtonSelected = YES;
    }
}

- (void)nextButtonPressed
{
    [self.delegate nextButtonPressed];
}

- (void)fullscreenButtonPressed
{
    _fullscreenButton.selected = !_fullscreenButton.selected;
    [self.delegate fullscreenButtonPressed];
}

- (void)singleTapPlayView
{
    if (_isControlsHidden) {
        [UIView animateWithDuration:0.9
                         animations:^{
                             _topControlOverlay.alpha = 0.f;
                             _bottomControlOverlay.alpha = 0.f;
        }];
        _isControlsHidden = NO;
    }else{
        [UIView animateWithDuration:0.9
                         animations:^{
                             _topControlOverlay.alpha = 1.f;
                             _bottomControlOverlay.alpha = 1.f;
                         }];
        _isControlsHidden = YES;
    }
}

#pragma mark - Touch & Gesture

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UISlider class]]) {
        [self touchesCancelled:touches withEvent:event];
    }
    _startPoint = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.mbProgress.alpha = 1.f;
    
    for (UITouch *touch in touches.allObjects) {
        CGPoint curPoint = [touch locationInView:self];
        CGPoint prePoint = [touch previousLocationInView:self];
        if (fabs(curPoint.y - _startPoint.y) > fabs(curPoint.x - _startPoint.x)) {
            float deltaY = curPoint.y - prePoint.y;
            [self.mbProgress hide:YES];
            [self changeVolumeWithDelta:deltaY];
        }else{
            if (self.bigPlayButton.hidden == NO) {
                self.bigPlayButton.hidden = YES;
            }
            float deltaX = curPoint.x - _startPoint.x;
            BOOL isForward = curPoint.x > prePoint.x ? YES : NO;
            [self updateMBProgressWithDelta:deltaX andForward:isForward];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)changeVolumeWithDelta:(float)d
{
    float systemVolume = 0.f;
    if (self.volumeSlider) {
        systemVolume = self.volumeSlider.value;
    }
    systemVolume -= d/50;
//    NSLog(@"volume: %f",systemVolume);
    [self.volumeSlider setValue:systemVolume animated:YES];
}

- (void)updateMBProgressWithDelta:(float)delta andForward:(BOOL)isForward
{
    self.mbProgress.customView = isForward ? [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"afterward"]] : [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"previous"]];
//    _seekTime = [self.gestureDelegate updateMBProgressWithCurrent:_currentTime andDelta:delta];
//    [self updateTimeLabels];
}

@end
