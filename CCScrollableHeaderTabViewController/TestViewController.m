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
   
    self.minHeightOfHeaderView = 0;
    [self configTabView];
    
    EmbedViewController *evc = [EmbedViewController new];
    EmbedViewController *evc1 = [EmbedViewController new];
    EmbedViewController *evc2 = [EmbedViewController new];

    self.viewControllers = @[evc, evc1, evc2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configTabView {
    //tabmenu
    CCSimpleTabItem *infoItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab1"
                                                                   color:RGB(96, 96, 96)
                                                        highlightedColor:[UIColor greenColor]];
    infoItem.defaultBackgroundColor = [UIColor clearColor];
    infoItem.selectedBackgroundColor = [UIColor clearColor];
    CCSimpleTabItem *cataItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab2"
                                                                   color:RGB(96, 96, 96)
                                                        highlightedColor:[UIColor greenColor]];
    cataItem.defaultBackgroundColor = [UIColor clearColor];
    cataItem.selectedBackgroundColor = [UIColor clearColor];
    CCSimpleTabItem *commentItem = [[CCSimpleTabItem alloc] initWithTitle:@"tab3"
                                                                      color:RGB(96, 96, 96)
                                                           highlightedColor:[UIColor greenColor]];
    commentItem.defaultBackgroundColor = [UIColor clearColor];
    commentItem.selectedBackgroundColor = [UIColor clearColor];
    [self.tabView setTabItems:@[infoItem, cataItem, commentItem]];
    self.tabView.backgroundColor = [UIColor clearColor];
    [self.tabView setIndicatorImage:[UIImage imageNamed:@"line"]];
}
@end
