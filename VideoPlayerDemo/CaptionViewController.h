//
//  CaptionViewController.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/10/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Calios: 
 *  Anyone who wanna contain CaptionViewController as a subview controller is expected to add observer for these two key.
 */
#define CaptionSizeKey             @"CaptionSizeKey"
#define CaptionTypeSelectedKey     @"CaptionTypeSelectedKey"

@interface CaptionViewController : UIViewController

@property (nonatomic, assign) BOOL      isCaptionOpen;
@property (nonatomic, assign) NSInteger selectedRow;

- (id)initWithFrame:(CGRect) frame andCaptionArray:(NSArray *)captions;

@end
