//
//  DPlayerViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayerViewController.h"
#import "DPlayerView.h"
#import "DUtility.h"
#import "Constant.h"
#import <WYPopoverController.h>
#import "CaptionViewController.h"

static void *ItemStatusContext = &ItemStatusContext;

@interface DPlayerViewController ()<DPlayerViewDelegate,WYPopoverControllerDelegate>

@property (nonatomic, strong) AVPlayer       *player;
@property (nonatomic, strong) AVPlayerItem   *playerItem;
@property (nonatomic, strong) NSURL          *url;


@property (nonatomic, strong) DPlayerView    *playerView;
@property (nonatomic, strong) WYPopoverController *captionPopover;
@property (nonatomic, strong) CaptionViewController *captionViewController;

@property (nonatomic, strong) NSString       *totalTime;
@property (nonatomic, strong) id             playbackTimeObserver;
//@property (nonatomic, strong) NSString       *currentTime;

@end

@implementation DPlayerViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _playerView = [[DPlayerView alloc]initWithFrame:frame];
        _playerView.delegate = self;
        _isFullScreen = NO;
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
    self.view = _playerView;
//    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
//        self.playerView.captionButton.hidden = NO;
//    }else{
//        self.playerView.captionButton.hidden = YES;
//    }
    
    [self loadAssetFromFile:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    
    [self.player pause];
}

#pragma mark - DPlayerViewDelegate
- (void)doneButtonPressed
{
    NSLog(@"===> close vc");
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        // TODO: force rotate to portrait.(0709)
    }
}

- (void)scrubberDidBegin
{
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
    [self.playerView.mbProgress hide:YES afterDelay:0.5f];
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
        
    }
}

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

- (void)fullscreenButtonPressed:(BOOL)isPortrait
{
//    if (isPortrait) {
//        self.playerView.transform = CGAffineTransformMakeRotation(M_PI_2);
//        self.playerView.frame = CGRectMake(0, 0, 568, 320);
//        [self.playerView.playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspectFill];
//
//    }
    // TODO: force rotate. (0709)
    _isFullScreen = self.playerView.fullscreenButton.isSelected;
    [[NSNotificationCenter defaultCenter] postNotificationName:DPlayerViewControllerForceRotateKey
                                                        object:[NSNumber numberWithBool:_isFullScreen]];
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
//    NSLog(@"mbprogress: %@, scrubber: %f",self.playerView.mbProgress.labelText,self.playerView.scrubber.value);
    
    return seekTime;
}

#pragma mark - KVO

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
            CMTime duration     = self.playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime          = [self convertTime:totalSecond];// 转换成播放时间
            [self.playerView.scrubber setMaximumValue:CMTimeGetSeconds(duration)];
            self.playerView.totalTimeLabel.text = _totalTime;
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatus failed");
        } else{
            NSLog(@"AVPlayerStatus unknown");
        }
    }
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration]; // 计算缓冲进度
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.playerView.loadProgress setProgress:timeInterval/totalDuration animated:YES];
    }
    
//    if ([keyPath isEqualToString:@"currentTime"]) {
//        float currentSecond = [(NSNumber *)object floatValue];
//        [self updateVideoSliderAndCurrent:currentSecond];
//    }
}

#pragma mark Public

- (void)loadAssetFromFile:(NSURL *)url
{
    _url = [NSURL URLWithString:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"];
//    _url = [NSURL URLWithString:@"http://v.stu.126.net/mooc-video/nos/mp4/2015/05/08/1534082_sd.mp4?key=6c41d0758a2adcb750df19fc676e233e992f14081da5a13ef55f55c91f6195acfb712b3978ccfb86ed7bd969c6d0c4f8c67828585d0e00dce9fbf66689cf9ff13389d1e4d0884757973a81a0fd01ce17fbc78293fd295082129821b9aafff760ac2d80000c602942fa4509942b9285fbe88c01d51083d19b7f37bb90ce91f584ff95aee726907876d470c935a98ed296b407c478a81499a24006d50e873b5912"];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                if (self.playerView.indicatorView.isAnimating) {
                    [self.playerView.indicatorView stopAnimating];
                }
                
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                // ensure that this is done before the playerItem is associated with the player
                [self.playerItem addObserver:self
                                  forKeyPath:@"status"
                                     options:NSKeyValueObservingOptionNew
                                     context:ItemStatusContext];
                [self.playerItem addObserver:self
                                  forKeyPath:@"loadedTimeRanges"
                                     options:NSKeyValueObservingOptionNew
                                     context:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                [self.playerView.playerLayerView setPlayer:self.player];
                self.playerView.playButton.selected = YES;
                [self.player play];
            }else{
                if (!self.playerView.indicatorView.isAnimating) {
                    [self.playerView.indicatorView startAnimating];
                }
            }
        });
    }];
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

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    __weak __typeof(self) weakself = self;
    self.playbackTimeObserver = [self.playerView.playerLayerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
//        [weakself setValue:[NSNumber numberWithFloat:currentSecond] forKey:@"currentTime"];
        [weakself updateVideoSliderAndCurrent:currentSecond];
    }];
}

- (void)updateVideoSliderAndCurrent:(CGFloat)currentSecond
{
    [self.playerView.scrubber setValue:currentSecond animated:YES];
    NSString *timeString = [self convertTime:currentSecond];
    self.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@/",timeString];
}

- (void)playerItemDidReachEnd:(NSNotification *)notif
{
    [self.player seekToTime:kCMTimeZero];
}

#pragma mark - duration & time
- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[self.playerView.playerLayerView.player currentItem] loadedTimeRanges];
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

#pragma mark - caption popover

- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller
{
    _captionPopover.delegate = nil;
    _captionPopover = nil;
}

@end
