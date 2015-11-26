//
//  SecondDetailViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 11/25/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import "SecondDetailViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface SecondDetailViewController ()

@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation SecondDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView
{
#warning by Calios: I wonder why this block never works.(1126)
    [self.imageManager requestPlayerItemForVideo:_videoAsset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        self.player = [self createPlayerByPrefixingItem:playerItem];
    }];
}

#pragma mark - Setter

- (void)setPlayer:(AVPlayer *)player
{
    if (self.storyboard) {
        AVPlayerViewController *playerVC = (AVPlayerViewController *)[self.childViewControllers firstObject] ? : [[AVPlayerViewController alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            playerVC.player = self.player;
        });
    }
}

- (void)setVideoAsset:(PHAsset *)videoAsset
{
    _videoAsset = videoAsset;
    [self configureView];
}

#pragma mark - Private

- (AVPlayer *)createPlayerByPrefixingItem:(AVPlayerItem *)item
{
    AVPlayerItem *countdown = [AVPlayerItem playerItemWithURL:[[NSBundle mainBundle] URLForResource:@"countdown_new" withExtension:@"mov"]];
    return [AVQueuePlayer queuePlayerWithItems:@[countdown]];
}

@end
