//
//  DPlayerViewController.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DPlayerViewController : UIViewController

@property (nonatomic, assign) BOOL isFullScreen;

- (id)initWithFrame:(CGRect)frame;
- (void)setFrame:(CGRect)frame;

@end
