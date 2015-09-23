//
//  DPlayerViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayerViewController.h"
#import "DUtility.h"
#import "Constant.h"
#import <WYPopoverController.h>
#import "CaptionViewController.h"

static void *ItemStatusContext = &ItemStatusContext;

@interface DPlayerViewController ()<DPlayerViewDelegate,WYPopoverControllerDelegate>

@property (nonatomic, strong) WYPopoverController   *captionPopover;
@property (nonatomic, strong) CaptionViewController *captionViewController;

@property (nonatomic, strong) NSString              *totalTime;
@property (nonatomic, strong) id                    playbackTimeObserver;
@property (nonatomic, strong) NSString              *currentTime;

@property (nonatomic, strong) NSArray               *urlArray;
@property (nonatomic, assign) NSInteger             currentIndex;
@property (nonatomic, assign) BOOL                  isSliding;      // 是否正在手势移动控制进度

@end

@implementation DPlayerViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _playerView = [[DPlayerView alloc]initWithFrame:frame];
        _playerView.delegate = self;
        _isFullScreen = NO;
        _currentIndex = 1;
        _isSliding = NO;
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
    
    _urlArray = @[@"http://mov.bn.netease.com/open-movie/nos/mp4/2015/09/06/SB1T622RF_sd.mp4",
                  @"http://mov.bn.netease.com/open-movie/nos/mp4/2015/09/06/SB1T1Q6JG_sd.mp4",
                  @"http://mov.bn.netease.com/open-movie/nos/mp4/2013/07/19/S937IJ6GU_sd.mp4",
                  @"http://v.stu.126.net/mooc-video/nos/mp4/2015/05/08/1534082_sd.mp4?key=6c41d0758a2adcb750df19fc676e233e992f14081da5a13ef55f55c91f6195acfb712b3978ccfb86ed7bd969c6d0c4f8c67828585d0e00dce9fbf66689cf9ff13389d1e4d0884757973a81a0fd01ce17fbc78293fd295082129821b9aafff760ac2d80000c602942fa4509942b9285fbe88c01d51083d19b7f37bb90ce91f584ff95aee726907876d470c935a98ed296b407c478a81499a24006d50e873b5912",
                  @"http://mov.bn.netease.com/movie/2012/12/4/U/S8H1PGF4U.mp4",
                  @"http://v.stu.126.net/mooc-video/nos/mp4/2015/05/08/1534082_sd.mp4?key=6c41d0758a2adcb750df19fc676e233e992f14081da5a13ef55f55c91f6195acfb712b3978ccfb86ed7bd969c6d0c4f8c67828585d0e00dce9fbf66689cf9ff13389d1e4d0884757973a81a0fd01ce17fbc78293fd295082129821b9aafff760ac2d80000c602942fa4509942b9285fbe88c01d51083d19b7f37bb90ce91f584ff95aee726907876d470c935a98ed296b407c478a81499a24006d50e873b5912"];
    
    [self setupUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //    if (self.player.rate > 0) {
    [self.player pause];
    //    }
    
    [self removeObserverFromPlayerItem:self.player.currentItem];
    [self removeNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (self.player.rate > 0) {
        [self.player pause];
    }
    [self removeObserverFromPlayerItem:self.player.currentItem];
    [self removeNotification];
}

#pragma mark - Private

- (void)setupUI
{
    [self player];
    [self.playerView.playerLayerView setPlayer:self.player];
    self.playerView.playerLayerView.frame = self.playerView.frame;
    self.playerView.playButton.selected = YES;
    self.playerView.fullscreenButton.selected = NO;
    
    [self.view addSubview: _playerView];

    [self.player play];
}

- (AVPlayer *)player
{
    if (!_player) {
        AVPlayerItem *playerItem = [self getPlayItem:_currentIndex];
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        [self addProgressObserver];
        [self addObserverToPlayerItem:playerItem];
    }
    return _player;
}

/**
 *  根据视频索引取得AVPlayerItem对象
 *
 *  @param videoIndex 视频顺序索引
 *
 *  @return AVPlayerItem对象
 */
-(AVPlayerItem *)getPlayItem:(NSInteger)videoIndex{
    NSString *urlStr=[_urlArray objectAtIndex:videoIndex];
    urlStr =[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url=[NSURL URLWithString:urlStr];
    AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:url];
    return playerItem;
}

#pragma mark - 通知
/**
 *  添加播放器通知
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */

- (void)playerItemDidReachEnd:(NSNotification *)notif
{
    [self.player seekToTime:kCMTimeZero];
    NSLog(@"视频播放完成.");
}

#pragma mark - 监控
/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver{
    AVPlayerItem *playerItem=self.player.currentItem;
    //这里设置每秒执行一次
    __weak __typeof(self) weakself = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current=CMTimeGetSeconds(time);
        float total=CMTimeGetSeconds([playerItem duration]);
//        NSLog(@"当前已经播放%.2fs.",current);
        if (current > 0.0) {
            if (!weakself.isSliding) {
                //            [weakself updateVideoSliderAndCurrent:current];
                [weakself.playerView.scrubber setValue:current animated:YES];
                NSString *timeString = [weakself convertTime:current];
                weakself.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@/",timeString];
            }
        }
    }];
}

/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:ItemStatusContext];
    //监控网络加载情况属性
    [playerItem addObserver:self
                 forKeyPath:@"loadedTimeRanges"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
}

-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{

    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
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
}
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

- (void)fullscreenButtonPressed:(BOOL)isPortrait
{
    /**
     *  http://stackoverflow.com/questions/12650137/how-to-change-the-device-orientation-programmatically-in-ios-6 (Calios: can't tell how desperately it saved me.)
     */
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
