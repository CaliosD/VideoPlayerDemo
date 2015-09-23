	//
//  DPlayer2ViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayer2ViewController.h"
#import "DUtility.h"
#import "Constant.h"

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerLoadedTimeRageObservationContext = &AVPlayerDemoPlaybackViewControllerLoadedTimeRageObservationContext;

@interface DPlayer2ViewController ()<DPlayerViewDelegate>

@property (nonatomic, strong) NSString *totalTime;
@property (nonatomic, strong) id       playbackTimeObserver;
@property (nonatomic, strong) NSString *currentTime;
@property (nonatomic, strong) NSURL    *lastURL;

// Private
@property (nonatomic, assign) BOOL     seekToZeroBeforePlay;
@property (nonatomic, assign) id       mTimeObserver;
@property (nonatomic, assign) float    mRestoreAfterScrubbingRate;
@property (nonatomic, assign) BOOL     isSeeking;
@property (nonatomic, assign) BOOL     isGestureSeeking;   // 是否正在手势移动进度


@end

@interface DPlayer2ViewController (Player)
- (void)removePlayerTimeObserver;
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)playerItemDidReachEnd:(NSNotification *)notification;
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end


@implementation DPlayer2ViewController

#pragma mark - Asset URL

- (void)setURL:(NSURL *)URL
{
    if (_mURL != URL) {
        _mURL = [URL copy];

        [self syncScrubber];
        [self updateTimeLabel];
        [self disableScrubber];
        [self disablePlayerButtons];
        
        if (self.mPlayer) {
            [self removePlayerTimeObserver];
            [self.mPlayer pause];
        }
        
        _lastURL = URL;
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset key "playable".
         */
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_mURL options:nil];
        NSArray *requestedKeys = @[@"playable"];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                [self prepareToPlayAsset:asset withKeys:requestedKeys];
            });
        }];
    }
}

- (NSURL *)URL
{
    return _mURL;
}

#pragma mark - Button Action Methods (DPlayerViewDelegate)

- (void)playButtonPressed
{
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (self.seekToZeroBeforePlay == YES) {
        self.seekToZeroBeforePlay = NO;
        [self.mPlayer seekToTime:kCMTimeZero];
    }
    
    [self.mPlayer play];
    
    [self showStopButton];
}

- (void)pauseButtonPressed
{
    [self.mPlayer pause];
    
    [self showPlayButton];
}

- (void)fullscreenButtonPressed:(BOOL)isPortrait
{
    /* http:stackoverflow.com/questions/12650137/how-to-change-the-device-orientation-programmatically-in-ios-6 (Calios: can't tell how desperately it saved me.) */
    
    UIInterfaceOrientation orientation = isPortrait ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
}

#pragma mark - Play, Stop buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    self.playerView.playButton.selected = YES;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    self.playerView.playButton.selected = NO;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
    if ([self isPlaying])
    {
        [self showStopButton];
    }
    else
    {
        [self showPlayButton];
    }
}

-(void)enablePlayerButtons
{
    self.playerView.playButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.playerView.playButton.enabled = NO;
}

#pragma mark - Time label update

- (void)updateTimeLabel
{
    NSDate *start = [NSDate date];

    
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        self.playerView.currentTimeLabel.text = @"--:--  /";
        self.playerView.totalTimeLabel.text = @"--:--";
        return;
    }
    if (![_lastURL.absoluteString isEqualToString:_mURL.absoluteString]) {
        self.playerView.currentTimeLabel.text = @"--:--  /";
        self.playerView.totalTimeLabel.text = @"--:--";
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        double time = 0;
            time = CMTimeGetSeconds([self.mPlayer currentTime]);
//
//            float minValue = [self.playerView.scrubber minimumValue];
//            float maxValue = [self.playerView.scrubber maximumValue];
//            time = (self.playerView.scrubber.value - minValue) * duration / (maxValue - minValue);
        NSString *currentSecond = [self convertTime:time];
//        NSLog(@"currentSecond: %@",currentSecond);
        self.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@  /",currentSecond];
        self.playerView.totalTimeLabel.text = [self convertTime:duration];
    }
    

    NSDate *end = [[NSDate alloc]init];
    NSTimeInterval interval = [end timeIntervalSinceDate:start];
//    NSLog(@"time spend: %f",interval);
}

#pragma mark - Gesture handler

- (float)updateMBProgressWithCurrent:(float)current andDelta:(float)delta
{
    float seekTime = [self currentSecond] + ceil(delta/2);
    
    if (seekTime < 0) {
        seekTime = 0.0;
    }
    else if (seekTime > [self currentItemDuration]){
        seekTime = [self currentItemDuration];
    }
    NSString *currentTime = [DSharedUtility timeStringFromSecondsValue:(int)seekTime];
    NSString *totalTime = [DSharedUtility timeStringFromSecondsValue:(int)[self currentItemDuration]];
    self.playerView.mbProgress.labelText = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
    [self updateTimeLabel];
    
    return seekTime;
}

#pragma mark - Movie scrubber control

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
- (void)initScrubberTimer
{
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth(self.playerView.scrubber.bounds);
        interval = 0.5f * duration / width;
    }
    
    /* Update the scrubber during normal playback. */
    __weak DPlayer2ViewController *weakSelf = self;
    self.mTimeObserver = [self.mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                    queue:NULL /* If you pass NULL, the main queue is used. */
                                                                usingBlock:^(CMTime time)
                                                                            {
                                                                                [weakSelf syncScrubber];
                                                                                [weakSelf updateTimeLabel];
                                                                            }];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
//    if (!_isGestureSeeking) {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            self.playerView.scrubber.minimumValue = 0.0;
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [self.playerView.scrubber minimumValue];
            float maxValue = [self.playerView.scrubber maximumValue];
            double time = CMTimeGetSeconds([self.mPlayer currentTime]);
            
            [self.playerView.scrubber setValue:(maxValue - minValue) * time / duration + minValue];
        }
//    }
//    else{
//        NSLog(@"syn :%f",self.playerView.scrubber.value);
////        self.playerView.scrubber
//    }
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)scrubberDidBegin
{
    self.mRestoreAfterScrubbingRate = [self.mPlayer rate];
    [self.mPlayer setRate:0.f];

    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (void)scrubberValueChangedWithSeekTime:(float)seekTime isSlider:(BOOL)isSlider
{
    if (!self.isSeeking) {
        self.isSeeking = YES;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            double dragTime = 0;
            if (isSlider) {
                float minValue = [self.playerView.scrubber minimumValue];
                float maxValue = [self.playerView.scrubber maximumValue];
                float value = [self.playerView.scrubber value];
                
                dragTime = duration * (value - minValue) / (maxValue - minValue);
            }
            else{
                dragTime = floor(seekTime);
            }
            
            NSLog(@"====== %f",dragTime);
            [self.mPlayer seekToTime:CMTimeMakeWithSeconds(dragTime, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
                if (finished) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isSeeking = NO;
                        [self.playerView.mbProgress hide:YES];
                    });
                }
            }];
        }
        //    }
    }

}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)scrubberDidEnd
{
    if (!self.mTimeObserver)
    {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
                CGFloat width = CGRectGetWidth([self.playerView.scrubber bounds]);
                double tolerance = 0.5f * duration / width;
                
                __weak DPlayer2ViewController *weakSelf = self;
                self.mTimeObserver = [self.mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                                      ^(CMTime time)
                                      {
                                          [weakSelf syncScrubber];
                                          [weakSelf updateTimeLabel];
                                      }];

        }
    }
    
    if (self.mRestoreAfterScrubbingRate)
    {
        [self.mPlayer setRate:self.mRestoreAfterScrubbingRate];
        self.mRestoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing
{
    return self.mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.playerView.scrubber.enabled = YES;
}

-(void)disableScrubber
{
    self.playerView.scrubber.enabled = NO;
}

#pragma mark - View Controller

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _playerView = [[DPlayerView alloc]initWithFrame:frame];
        _playerView.delegate = self;
        _isFullScreen = NO;
        _isSeeking = NO;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [_playerView setFrame:frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUI];
    
    [self initScrubberTimer];
    [self syncPlayPauseButtons];
    [self syncScrubber];
    [self updateTimeLabel];
}

- (void)setupUI
{
    [self setPlayer:nil];
    
    self.playerView.playerLayerView.frame = self.playerView.frame;
    //    self.playerView.playButton.selected = YES;
    self.playerView.fullscreenButton.selected = NO;
    
    [self.view addSubview: _playerView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.mPlayer pause];
    
//    [self removeObserverFromPlayerItem:self.player.currentItem];
//    [self removeNotification];
    
    [super viewWillDisappear:animated];
}

-(void)setViewDisplayName
{
    /* Set the view title to the last component of the asset URL. */
    self.title = [_mURL lastPathComponent];
    
    /* Or if the item has a AVMetadataCommonKeyTitle metadata, use that instead. */
    for (AVMetadataItem* item in ([[[self.mPlayer currentItem] asset] commonMetadata]))
    {
        NSString* commonKey = [item commonKey];
        
        if ([commonKey isEqualToString:AVMetadataCommonKeyTitle])
        {
            self.title = [item stringValue];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self removePlayerTimeObserver];
    
    [self.mPlayer removeObserver:self forKeyPath:@"rate"];
    [self.mPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    
    [self.mPlayer pause];
}


#pragma mark - Duration & Time

- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[self.playerView.playerLayerView.player currentItem] loadedTimeRanges];
    //    NSLog(@"rages : %@" ,loadedTimeRanges);
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];    // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算缓冲总进度
    return result;
}

- (NSString *)convertTime:(CGFloat)second
{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

- (CGFloat)currentSecond
{
    CGFloat currentSecond = self.player.currentItem.currentTime.value/self.player.currentItem.currentTime.timescale;
    return currentSecond;
}

- (CGFloat)currentItemDuration
{
    CGFloat currentItemDuration = self.player.currentItem.duration.value/self.player.currentItem.duration.timescale;
    return currentItemDuration;
}

@end

@implementation DPlayer2ViewController (Player)

#pragma mark Player Item

- (BOOL)isPlaying
{
    return self.mRestoreAfterScrubbingRate != 0.f || [self.mPlayer rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    self.seekToZeroBeforePlay = YES;
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.mPlayer currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (self.mTimeObserver)
    {
        [self.mPlayer removeTimeObserver:self.mTimeObserver];
        self.mTimeObserver = nil;
    }
}


#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self updateTimeLabel];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */

    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */

        [self.mPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.mPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    /* Observe the network loading status. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"loadedTimeRanges"
                          options:NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerLoadedTimeRageObservationContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
    
    self.seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (!self.mPlayer)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.mPlayerItem]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        [self.mPlayer replaceCurrentItemWithPlayerItem:self.mPlayerItem];
        
        [self syncPlayPauseButtons];
    }
    
    [self.playerView.scrubber setValue:0.0];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext)
    {
        [self syncPlayPauseButtons];
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            /* Indicates that the status of the player is not yet known because
             it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown: {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                [self updateTimeLabel];
                
                self.playerView.userInteractionEnabled = NO;

                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
            case AVPlayerItemStatusReadyToPlay: {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                [self enableScrubber];
                [self enablePlayerButtons];
                
                self.playerView.userInteractionEnabled = YES;

                [self.player play];
            }
                break;
            case AVPlayerItemStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }
    
    /* AVPlayer "rate" property value observer. */
    else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
    {
        [self syncPlayPauseButtons];
    }
    
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
        }
        else  /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self.playerView.playerLayerView setPlayer:self.mPlayer];
            
            [self setViewDisplayName];
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            [self.playerView.playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
    }
    else if (context == AVPlayerDemoPlaybackViewControllerLoadedTimeRageObservationContext)
    {
        NSTimeInterval timeInterval = [self availableDuration]; // 计算缓冲进度
        CMTime duration = self.mPlayerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.playerView.loadProgress setProgress:timeInterval/totalDuration animated:YES];
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

@end












/**
 *  根据视频索引取得AVPlayerItem对象
 *
 *  @param videoIndex 视频顺序索引
 *
 *  @return AVPlayerItem对象
 */
//-(AVPlayerItem *)getPlayItem:(NSInteger)videoIndex{
//    NSString *urlStr=[_urlArray objectAtIndex:videoIndex];
//    urlStr =[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSURL *url=[NSURL URLWithString:urlStr];
//    AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:url];
//    return playerItem;
//}
//
//#pragma mark - 通知
///**
// *  添加播放器通知
// */
//-(void)addNotification{
//    //给AVPlayerItem添加播放完成通知
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(playerItemDidReachEnd:)
//                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                               object:self.player.currentItem];
//}
//
//-(void)removeNotification{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
///**
// *  播放完成通知
// *
// *  @param notification 通知对象
// */
//
//- (void)playerItemDidReachEnd:(NSNotification *)notif
//{
//    [self.player seekToTime:kCMTimeZero];
//    NSLog(@"视频播放完成.");
//}
//
//#pragma mark - 监控
///**
// *  给播放器添加进度更新
// */
//-(void)addProgressObserver{
//    AVPlayerItem *playerItem=self.player.currentItem;
//    //这里设置每秒执行一次
//    __weak __typeof(self) weakself = self;
//    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
//        float current=CMTimeGetSeconds(time);
//        float total=CMTimeGetSeconds([playerItem duration]);
//        //        NSLog(@"当前已经播放%.2fs.",current);
//        if (current > 0.0) {
//            if (!weakself.isSliding) {
//                //            [weakself updateVideoSliderAndCurrent:current];
//                [weakself.playerView.scrubber setValue:current animated:YES];
//                NSString *timeString = [weakself convertTime:current];
//                weakself.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@/",timeString];
//            }
//        }
//    }];
//}
//
///**
// *  给AVPlayerItem添加监控
// *
// *  @param playerItem AVPlayerItem对象
// */
//-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
//    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
//    [playerItem addObserver:self
//                 forKeyPath:@"status"
//                    options:NSKeyValueObservingOptionNew
//                    context:ItemStatusContext];
//    //监控网络加载情况属性
//    [playerItem addObserver:self
//                 forKeyPath:@"loadedTimeRanges"
//                    options:NSKeyValueObservingOptionNew
//                    context:nil];
//}
/*
-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}
*/
/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
/*
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if (context == ItemStatusContext && [keyPath isEqualToString:@"status"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self synStartButton];
        });
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            CMTime duration     = playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime          = [self convertTime:totalSecond];// 转换成播放时间
            [self.playerView.scrubber setMaximumValue:CMTimeGetSeconds(duration)];
            self.playerView.currentTimeLabel.text = @"00:00/";
            self.playerView.totalTimeLabel.text = _totalTime;
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatus failed");
        } else{
            NSLog(@"AVPlayerStatus unknown");
        }
    }
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration]; // 计算缓冲进度
        CMTime duration = playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //        NSLog(@"----- %f,%f",timeInterval,totalDuration);
        [self.playerView.loadProgress setProgress:timeInterval/totalDuration animated:YES];
    }
    
    //        if ([keyPath isEqualToString:@"currentTime"]) {
    //            float currentSecond = [(NSNumber *)object floatValue];
    //            [self updateVideoSliderAndCurrent:currentSecondaddProgressObserver];
    //        }
}

#pragma mark - DPlayerViewDelegate
- (void)doneButtonPressed
{
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    }else{
        NSLog(@"===> close vc");
    }
}

- (void)scrubberDidBegin
{
    self.isSliding = YES;
    [self.player pause];
}

- (void)scrubberValueChangedWithSeekTime:(float)seekTime
{
    double currentTime = floor(seekTime);
    CMTime dragTime = CMTimeMake(currentTime, 1);
    [self.player seekToTime:dragTime completionHandler:^(BOOL finished) {
        if (finished) {
            [self.playerView.mbProgress hide:YES];
            [self.player play];
        }
    }];
    
}

- (void)scrubberDidEnd
{
    self.isSliding = NO;
}

- (void)playButtonPressed
{
    [self.player play];
}

- (void)pauseButtonPressed
{
    [self.player pause];
}

- (void)nextButtonPressed
{
    if (self.player.currentItem) {
        if (_currentIndex + 1 < _urlArray.count) {
            _playerView.nextButton.enabled = YES;
            [self navigationButtonClick:_currentIndex + 1];
        }
        else{
            _playerView.nextButton.enabled = NO;
        }
        //        NSLog(@"======> observedBitrate: %f",[(AVPlayerItemAccessLogEvent *)[self.playerItem.accessLog.events lastObject] observedBitrate]);
        //        NSLog(@"======> indicatedBitrate: %f",[(AVPlayerItemAccessLogEvent *)[self.playerItem.accessLog.events lastObject] indicatedBitrate]);
        //        NSLog(@"======> preferredPeakBitRate: %f",[self.playerItem preferredPeakBitRate]);
        
    }
}*/
/*
 - (void)captionButtonPressed
 {
 // Mock.
 NSArray *captionArray = @[@"中文",@"英文"];
 BOOL isCaptionOpen = YES;
 // Mock end.
 
 CGFloat popHeight = isCaptionOpen ? 44 * (captionArray.count + 2) : 44;
 
 _captionViewController = [[CaptionViewController alloc]initWithFrame:CGRectMake(0, 0, 280, popHeight) andCaptionArray:captionArray];
 _captionViewController.isCaptionOpen = isCaptionOpen;
 
 _captionPopover = [[WYPopoverController alloc]initWithContentViewController:_captionViewController];
 _captionViewController.preferredContentSize = CGSizeMake(280, popHeight);
 _captionPopover.delegate = self;
 [_captionPopover presentPopoverFromRect:_playerView.captionButton.bounds inView:_playerView.captionButton permittedArrowDirections:WYPopoverArrowDirectionDown animated:YES];
 }
 */
/*
- (void)fullscreenButtonPressed:(BOOL)isPortrait
{
 
       http:stackoverflow.com/questions/12650137/how-to-change-the-device-orientation-programmatically-in-ios-6 (Calios: can't tell how desperately it saved me.)
 
    UIInterfaceOrientation orientation = isPortrait ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
}

- (float)updateMBProgressWithCurrent:(float)current andDelta:(float)delta
{
    float seekTime = [self currentSecond] + ceil(delta/2);
    
    if (seekTime < 0) {
        seekTime = 0.0;
    }
    else if (seekTime > [self currentItemDuration]){
        seekTime = [self currentItemDuration];
    }
    NSString *currentTime = [DSharedUtility timeStringFromSecondsValue:(int)seekTime];
    NSString *totalTime = [DSharedUtility timeStringFromSecondsValue:(int)[self currentItemDuration]];
    self.playerView.mbProgress.labelText = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
    [self.playerView.scrubber setValue:seekTime animated:YES];
    NSLog(@"mbprogress: %@, scrubber: %f",self.playerView.mbProgress.labelText,self.playerView.scrubber.value);
    
    return seekTime;
}

- (void)navigationButtonClick:(NSInteger)index {
    if (_currentIndex != index) {
        _currentIndex = index;
        _playerView.nextButton.enabled = (_currentIndex < _urlArray.count - 1) ? YES : NO;
        
        [self removeNotification];
        [self removeObserverFromPlayerItem:self.player.currentItem];
        
        AVPlayerItem *playerItem=[self getPlayItem:index];
        [self addObserverToPlayerItem:playerItem];
        //切换视频
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [self addNotification];
        [self.playerView.scrubber setValue:0.0 animated:YES];
        self.playerView.currentTimeLabel.text = @"00:00/";
        [self.playerView.loadProgress setProgress:0.0 animated:YES];
    }
}

#pragma mark - Player

- (void)synStartButton
{
    if ((self.player.currentItem != nil) && (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay)) {
        self.playerView.playButton.enabled = YES;
        self.playerView.playButton.selected = YES;
    }
    else{
        self.playerView.playButton.enabled = NO;
        self.playerView.playButton.selected = NO;
    }
}

- (void)updateVideoSliderAndCurrent:(CGFloat)currentSecond
{
    [self.playerView.scrubber setValue:currentSecond animated:YES];
    NSString *timeString = [self convertTime:currentSecond];
    self.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@/",timeString];
}

#pragma mark - duration & time
- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[self.playerView.playerLayerView.player currentItem] loadedTimeRanges];
    //    NSLog(@"rages : %@" ,loadedTimeRanges);
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];    // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算缓冲总进度
    return result;
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

- (CGFloat)currentSecond
{
    CGFloat currentSecond = self.player.currentItem.currentTime.value/self.player.currentItem.currentTime.timescale;
    return currentSecond;
}

- (CGFloat)currentItemDuration
{
    CGFloat currentItemDuration = self.player.currentItem.duration.value/self.player.currentItem.duration.timescale;
    return currentItemDuration;
}
*/
