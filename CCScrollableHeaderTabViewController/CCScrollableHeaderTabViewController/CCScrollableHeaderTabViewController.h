//
//  CCScrollableHeaderTabViewController.h
//  Edu901iPhone
//
//  Created by ddrccw on 15-1-5.
//  Copyright (c) 2015年 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCSimpleTabView.h"

typedef NS_ENUM(NSUInteger, CCScrollableHeaderScrollDirection) {
    CCScrollableHeaderScrollDirectionUnknown,
    CCScrollableHeaderScrollDirectionUp,
    CCScrollableHeaderScrollDirectionDown
};

@class CCScrollableHeaderTabViewController;

//!IMPORTANT: 如果sub vc里面有scrollView，需要实现这个回调
@protocol CCScrollableHeaderTabViewControllerViewSource <NSObject>
@optional
- (UIScrollView *)scrollableSubViewInSubViewController:(UIViewController *)subViewController;
- (BOOL)shouldScrollToTopWhenTableHeaderViewChange;
@end

@protocol CCScrollableHeaderDelegate <NSObject>
@optional
- (void)headerViewDidScrollWithOffsetY:(CGFloat)offsetY
                       scrollDirection:(CCScrollableHeaderScrollDirection)scrollDirection;

@end

@protocol CCScrollableHeaderTabDelegate <NSObject>
@optional
- (void)scrollableHeaderTabViewController:(CCScrollableHeaderTabViewController *)scrollableHeaderTabViewController
                      didSelectTabAtIndex:(NSInteger)index;
@end


@interface CCScrollableHeaderTabViewController : UIViewController
<CCSimpleTabViewDelegate, CCScrollableHeaderDelegate, CCScrollableHeaderTabDelegate>

//!IMPORTANT: must be configured
@property (weak, nonatomic) IBOutlet UIScrollView *containerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerViewTopContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet CCSimpleTabView *tabView;

@property (assign, nonatomic) NSInteger maxHeightOfHeaderView;
@property (assign, nonatomic) NSInteger minHeightOfHeaderView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, assign) BOOL scrollToTop;
@property (strong, nonatomic, readonly) NSArray *viewControllers;

- (void)setViewControllers:(NSArray *)viewControllers;
- (void)setHeaderViewTopContraintWithValue:(CGFloat)value;
- (CGFloat)estimateHeaderViewTopContraint;
@end


@interface UIScrollView (CCScrollableHeaderTabViewController)
@property (weak, nonatomic) CCScrollableHeaderTabViewController *scrollObserver;
- (void)addObserverForContentOffset;
- (void)removeObserverForContentOffset;
@end