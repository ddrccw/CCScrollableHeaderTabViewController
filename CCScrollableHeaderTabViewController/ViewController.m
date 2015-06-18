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
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellId];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"default: navibar.hidden=NO, not scroll to top";
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"navibar.hidden=NO, auto scroll to top";
    }
    else if (indexPath.row == 2) {
        cell.textLabel.text = @"navibar.hidden=YES, not scroll to top";
    }
    else if (indexPath.row == 3) {
        cell.textLabel.text = @"navibar.hidden=YES, auto scroll to top";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TestViewController *tvc = [TestViewController new];
    tvc.index = indexPath.row;
    if (indexPath.row == 0) {
    }
    else if (indexPath.row == 1) {
        tvc.scrollToTop = YES;
    }
    else if (indexPath.row == 2) {
        
    }
    else if (indexPath.row == 3) {
        tvc.scrollToTop = YES;
    }

    [self.navigationController pushViewController:tvc animated:YES];
}
@end
