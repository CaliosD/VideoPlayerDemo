//
//  DUtility.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/9/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "DUtility.h"

@implementation DUtility

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *)timeStringFromSecondsValue:(int)seconds
{
    NSString *retVal;
    int hours = seconds / 3600;
    int minutes = (seconds / 60) % 60;
    int secs = seconds % 60;
    if (hours > 0) {
        retVal = [NSString stringWithFormat:@"%01d:%02d:%02d", hours, minutes, secs];
    } else {
        retVal = [NSString stringWithFormat:@"%02d:%02d", minutes, secs];
    }
    return retVal;
}

@end
