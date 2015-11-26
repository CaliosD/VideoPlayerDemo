//
//  SecondListTableViewCell.m
//  VideoPlayerDemo
//
//  Created by Calios on 11/25/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import "SecondListTableViewCell.h"

@implementation SecondListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 150, 150)];
        self.videoNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(170, 40, 100, 20)];
        [self.contentView addSubview:self.thumbnailImageView];
        [self.contentView addSubview:self.videoNameLabel];
    }
    return self;
}

- (void)setVideoAsset:(PHAsset *)videoAsset
{
    _videoAsset = videoAsset;
    [self configureView];
}

- (void)configureView
{
    if (_videoAsset) {
        NSString *durationString = [NSString stringWithFormat:@"%.1f",_videoAsset.duration];
        self.videoNameLabel.text = [NSString stringWithFormat:@"%@s",durationString];
        [self.imageManager requestImageForAsset:_videoAsset targetSize:CGSizeMake(150, 150) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            self.thumbnailImageView.image = result;
        }];
    }
}
@end
