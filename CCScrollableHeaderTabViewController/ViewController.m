//
//  ViewController.m
//  CCScrollableHeaderTabViewController
//
//  Created by ddrccw on 15/6/18.
//  Copyright (c) 2015年 ddrccw. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"

@interface ViewController ()
<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - table view data souce and delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellId];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"default";
    }
    else {
        cell.textLabel.text = @"auto scroll to top";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TestViewController *tvc = [TestViewController new];
    tvc.index = indexPath.row;
    if (indexPath.row == 0) {

    }
    else {
        tvc.scrollToTop = YES;
    }

    [self.navigationController pushViewController:tvc animated:YES];
}
@end
