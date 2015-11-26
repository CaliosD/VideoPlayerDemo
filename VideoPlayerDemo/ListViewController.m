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
#import "DPlayer2ViewController.h"



@interface ListViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) DPlayer2ViewController *playerController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray   *urlArray;

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _urlArray = @[@"http://mov.bn.netease.com/movie/2012/12/4/U/S8H1PGF4U.mp4",
                  @"http://mov.bn.netease.com/open-movie/nos/mp4/2015/09/06/SB1T1Q6JG_sd.mp4",
                  @"http://mov.bn.netease.com/open-movie/nos/mp4/2013/07/19/S937IJ6GU_sd.mp4",
                  @"http://v.stu.126.net/mooc-video/nos/mp4/2015/05/08/1534082_sd.mp4?key=6c41d0758a2adcb750df19fc676e233e992f14081da5a13ef55f55c91f6195acfb712b3978ccfb86ed7bd969c6d0c4f8c67828585d0e00dce9fbf66689cf9ff13389d1e4d0884757973a81a0fd01ce17fbc78293fd295082129821b9aafff760ac2d80000c602942fa4509942b9285fbe88c01d51083d19b7f37bb90ce91f584ff95aee726907876d470c935a98ed296b407c478a81499a24006d50e873b5912",
                  @"http://mov.bn.netease.com/movie/2012/12/4/U/S8H1PGF4U.mp4",
                  @"http://v.stu.126.net/mooc-video/nos/mp4/2015/05/08/1534082_sd.mp4?key=6c41d0758a2adcb750df19fc676e233e992f14081da5a13ef55f55c91f6195acfb712b3978ccfb86ed7bd969c6d0c4f8c67828585d0e00dce9fbf66689cf9ff13389d1e4d0884757973a81a0fd01ce17fbc78293fd295082129821b9aafff760ac2d80000c602942fa4509942b9285fbe88c01d51083d19b7f37bb90ce91f584ff95aee726907876d470c935a98ed296b407c478a81499a24006d50e873b5912"];
    
    
    _playerController = [[DPlayer2ViewController alloc]initWithFrame:CGRectMake(0, 0, kScreenSize.width, kScreenSize.height/3 + 64)];
    [self addChildViewController:_playerController];
    [self.view addSubview:_playerController.view];
    [_playerController didMoveToParentViewController:self];

    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, kScreenSize.height/3 + 64, kScreenSize.width, kScreenSize.height - kScreenSize.height/3 - 64) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_playerController setURL:[NSURL URLWithString:[_urlArray objectAtIndex:0]]];
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
    return _urlArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"DemoRootTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    // Set value for cell
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld",(long)indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _playerController.shouldCancelLoading = NO;
    [_playerController setURL:[NSURL URLWithString:[_urlArray objectAtIndex:indexPath.row]]];
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
            [_playerController setFrame:CGRectMake(0, 0, MIN(kScreenSize.width,kScreenSize.height), (MAX(kScreenSize.height, kScreenSize.width)/3) + 64)];
        }
        [_playerController.view updateConstraints];
    }

}

@end
