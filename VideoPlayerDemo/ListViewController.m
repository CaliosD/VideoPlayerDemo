//
//  ListViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/6/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "ListViewController.h"
#import <PureLayout/PureLayout.h>

#import "Constant.h"
#import "DPlayerViewController.h"



@interface ListViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) DPlayerViewController *playerController;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _playerController = [[DPlayerViewController alloc]initWithFrame:CGRectMake(0, 0, kScreenSize.width, kScreenSize.height/3 + 64)];
    [self addChildViewController:_playerController];
    [self.view addSubview:_playerController.view];
    [_playerController didMoveToParentViewController:self];

    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, kScreenSize.height/3, kScreenSize.width, kScreenSize.height - kScreenSize.height/3) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"DemoRootTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    // Set value for cell
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - Orientation
- (void)orientationChanged:(NSNotification *)notif
{
    if ([notif.object isKindOfClass:[UIDevice class]]) {
        UIDevice *device = notif.object;
        if (device.orientation == UIInterfaceOrientationLandscapeLeft || device.orientation == UIInterfaceOrientationLandscapeRight) {
            _tableView.hidden = YES;
            [_playerController setFrame:CGRectMake(0, 0, MAX(kScreenSize.width, kScreenSize.height),MIN(kScreenSize.width, kScreenSize.height))];
        }else if (device.orientation == UIInterfaceOrientationPortrait){
            _tableView.hidden = NO;
            [_playerController setFrame:CGRectMake(0, 0, MIN(kScreenSize.width,kScreenSize.height), MAX(kScreenSize.height, kScreenSize.width)/3)];
        }
        [_playerController.view updateConstraints];
    }

}

@end
