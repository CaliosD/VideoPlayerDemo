//
//  DUtility.h
//  VideoPlayerDemo
//
//  Created by Calios on 7/9/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DSharedUtility    [DUtility sharedInstance]

@interface DUtility : NSObject

+ (instancetype)sharedInstance;

/**
 *  秒转字符串
 */
- (NSString *)timeStringFromSecondsValue:(int)seconds;

@end
