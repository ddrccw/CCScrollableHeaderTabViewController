//
//  EmbedViewController.m
//  CCScrollableHeaderTabViewController
//
//  Created by ddrccw on 15/6/18.
//  Copyright (c) 2015年 ddrccw. All rights reserved.
//

#import "EmbedViewController.h"

@interface EmbedViewController ()
<UITableViewDelegate, UITableViewDataSource, CCScrollableHeaderTabViewControllerViewSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation EmbedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIScrollView *)scrollableSubViewInSubViewController:(id)subViewController {
    return self.tableView;
}

#pragma mark - table view data souce and delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return arc4random() % 50 + 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellId];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"hello %d", indexPath.row];
    return cell;
}
@end
