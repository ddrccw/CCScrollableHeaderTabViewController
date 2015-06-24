//
//  TestViewController.m
//  CCScrollableHeaderTabViewController
//
//  Created by ddrccw on 15/6/18.
//  Copyright (c) 2015年 ddrccw. All rights reserved.
//

#import "TestViewController.h"
#import "EmbedViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
   
    if (self.index == 0) {
        self.minHeightOfHeaderView = 0;
        [self.navigationController setNavigationBarHidden:NO];
    }
    else if (self.index == 1){
        self.minHeightOfHeaderView = 0;
        [self.navigationController setNavigationBarHidden:NO];
    }
    else if (self.index == 2){
        [self.navigationController setNavigationBarHidden:YES];
    }
    else {
        [self.navigationController setNavigationBarHidden:YES];
    }
    [self configTabView];
    
    EmbedViewController *evc = [EmbedViewController new];
    EmbedViewController *evc1 = [EmbedViewController new];
    EmbedViewController *evc2 = [EmbedViewController new];

    self.viewControllers = @[evc, evc1, evc2];
    
//    self.selectedIndex = 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configTabView {
    //tabmenu
    CCSimpleTabItem *infoItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab1"
                                                                   color:RGB(96, 96, 96)
                                                        highlightedColor:[UIColor greenColor]];
    infoItem.defaultBackgroundColor = [UIColor clearColor];
    infoItem.selectedBackgroundColor = [UIColor blueColor];
    CCSimpleTabItem *cataItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab2"
                                                                   color:RGB(96, 96, 96)
                                                        highlightedColor:[UIColor greenColor]];
    cataItem.defaultBackgroundColor = [UIColor clearColor];
    cataItem.selectedBackgroundColor = [UIColor purpleColor];
    CCSimpleTabItem *commentItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab3"
                                                                      color:RGB(96, 96, 96)
                                                           highlightedColor:[UIColor greenColor]];
    commentItem.defaultBackgroundColor = [UIColor clearColor];
    commentItem.selectedBackgroundColor = [UIColor grayColor];
    [self.tabView setTabItems:@[infoItem, cataItem, commentItem]];
    self.tabView.backgroundColor = [UIColor yellowColor];
    [self.tabView setIndicatorImage:[UIImage imageNamed:@"line"]];
}
@end
