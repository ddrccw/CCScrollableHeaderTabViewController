//
//  CCScrollableHeaderTabViewController.h
//  
//
//  Created by ddrccw on 15-1-5.
//  Copyright (c) 2015年 ddrccw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+Utility.h"
#import "CCSimpleTabView.h"

//!IMPORTANT: 如果sub vc里面有scrollView，需要实现这个回调
@protocol CCScrollableHeaderTabViewControllerViewSource <NSObject>
@optional
- (UIScrollView *)scrollableSubViewInSubViewController:(id)subViewController;
- (BOOL)shouldScrollToTopWhenTableHeaderViewChange;
@end

@protocol CCScrollableHeaderDelegate <NSObject>
@optional
- (void)headerViewDidScrollWithOffsetY:(CGFloat)offsetY;
@end

@interface CCScrollableHeaderTabViewController : UIViewController
<CCSimpleTabViewDelegate, CCScrollableHeaderDelegate>

//!IMPORTANT: must be configured
@property (weak, nonatomic) IBOutlet UIScrollView *containerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerViewTopContraint;
@property (weak, nonatomic) IBOutlet CCSimpleTabView *tabView;

@property (assign, nonatomic) NSInteger maxHeightOfHeaderView;
@property (assign, nonatomic) NSInteger minHeightOfHeaderView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, assign) BOOL scrollToTop;
@property (strong, nonatomic, readonly) NSArray *viewControllers;

- (void)setViewControllers:(NSArray *)viewControllers;
@end
