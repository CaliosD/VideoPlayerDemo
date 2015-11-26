//
//  SecondListTableViewCell.h
//  VideoPlayerDemo
//
//  Created by Calios on 11/25/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface SecondListTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *videoNameLabel;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) PHAsset *videoAsset;

- (void)configureView;

@end
