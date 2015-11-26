//
//  SecondListViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 11/20/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import "SecondListViewController.h"
#import "SecondDetailViewController.h"
#import "SecondListTableViewCell.h"

#import <Photos/Photos.h>

@interface SecondListViewController ()

@property (nonatomic, strong) PHFetchResult *videos;
@property (nonatomic, strong) PHImageManager *imageManager;

@end

@implementation SecondListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _videos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
    _imageManager = [PHImageManager defaultManager];
    
    self.tableView.rowHeight = 170;
    [self.tableView registerClass:[SecondListTableViewCell class] forCellReuseIdentifier:@"SecondCell"];

    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SecondListTableViewCell *cell = (SecondListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SecondCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[SecondListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SecondCell"];
    }
    cell.imageManager = _imageManager;
    cell.videoAsset = (PHAsset *)_videos[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SecondDetailViewController *detailVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([SecondDetailViewController class])];
    detailVC.videoAsset = (PHAsset *)_videos[indexPath.row];
    [self.navigationController pushViewController:detailVC animated:NO];
}
@end
