//
//  DPlayerLayerView.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DPlayerLayerView.h"

@implementation DPlayerLayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

// 单纯使用AVPlayer类是无法显示视频的，要将视频层添加至AVPlayerLayer中，这样才能将视频显示出来。
- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

// 指定video在player layer的bounds内如何显示。（默认是AVLayerVideoGravityResizeAspect）
/* 可选项：
 * AVLayerVideoGravityResizeAspect，保证宽高比，在layer的bounds内正常显示；
 * AVLayerVideoGravityResizeAspectFill，保证宽高比，填充满layer的bounds；
 * AVLayerVideoGravityResize，拉伸来填满layer的bounds。
 */
- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
