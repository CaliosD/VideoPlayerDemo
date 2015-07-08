//
//  DPlayerViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayerViewController.h"
#import "DPlayerView.h"

static void *ItemStatusContext = &ItemStatusContext;

@interface DPlayerViewController ()<DPlayerViewDelegate>

@property (nonatomic, strong) AVPlayer       *player;
@property (nonatomic, strong) AVPlayerItem   *playerItem;
@property (nonatomic, strong) NSURL          *url;


@property (nonatomic, strong) DPlayerView    *playerView;

@property (nonatomic, strong) NSString       *totalTime;
@property (nonatomic, strong) id             playbackTimeObserver;


//- (void)loadAssetFromFile:(NSURL *)url;
//- (void)playButtonPressed;
//- (void)synStartButton;

@end

@implementation DPlayerViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _playerView = [[DPlayerView alloc]initWithFrame:frame];
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
}

- (void)scrubberValueChanged:(UISlider *)sender
{
    
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

}
- (void)fullscreenButtonPressed
{
    
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
    
    if ([keyPath isEqualToString:@"currentTime"]) {
        self.playerView.currentTimeLabel.text = self.playerView.currentTime;
    }
}

#pragma mark Private

- (void)loadAssetFromFile:(NSURL *)url
{
    _url = [NSURL URLWithString:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
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
                [self.player play];
            }
        });
    }];
}

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
        [weakself updateVideoSlider:currentSecond];
        NSString *timeString = [weakself convertTime:currentSecond];
        weakself.playerView.currentTimeLabel.text = [NSString stringWithFormat:@"%@/",timeString];
        weakself.playerView.currentTime = timeString;
        weakself.playerView.totalTime = weakself.totalTime;
        weakself.playerView.totalTimeLabel.text = weakself.totalTime;
    }];
}

- (void)updateVideoSlider:(CGFloat)currentSecond
{
    [self.playerView.scrubber setValue:currentSecond animated:YES];
}

- (void)playerItemDidReachEnd:(NSNotification *)notif
{
    [self.player seekToTime:kCMTimeZero];
}

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

@end
