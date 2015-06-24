//
//  CCScrollableHeaderTabViewController.m
//  
//
//  Created by ddrccw on 15-1-5.
//  Copyright (c) 2015年 ddrccw. All rights reserved.
//

#import "CCScrollableHeaderTabViewController.h"
#import <POP.h>

static NSString * const kPanDecelerateKey = @"decelerate";
static NSString * const kPanBounceKey = @"bounce";

@interface CCScrollableHeaderTabViewController ()
<UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL fixLayoutProblemLessThenIOS8_;
}
@property (strong, nonatomic, readwrite) NSArray *viewControllers;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureInHeaderView;
@property (assign, nonatomic) CGPoint lastLocationWhenPanning;
@property (assign, nonatomic) CGPoint startOffsetWhenPanning;
@property (assign, nonatomic) CGPoint endOffsetWhenPanning;
@end

@implementation CCScrollableHeaderTabViewController

+ (BOOL)isEqualOrGreaterThanIOS7 {
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) ? YES : NO;
}

+ (BOOL)isEqualOrGreaterThanIOS8 {
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) ? YES : NO;
}

- (void)dealloc {
    _containerView.delegate = nil;
    [self removeChildViewControllersAndObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabView.delegate = self;
    self.containerView.showsVerticalScrollIndicator = YES;
    self.containerView.showsHorizontalScrollIndicator = NO;
    self.containerView.clipsToBounds = YES;
    self.containerView.pagingEnabled = YES;
    self.containerView.bounces = NO;
    self.containerView.delegate = self;
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    _maxHeightOfHeaderView = self.headerView.bounds.size.height;
    if ([self.class isEqualOrGreaterThanIOS7]) {
        _minHeightOfHeaderView = 20;
    }
    else {
        _minHeightOfHeaderView = 0;
    }
    
    self.panGestureInHeaderView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panInHeaderView:)];
    self.panGestureInHeaderView.delegate = self;
    [self.headerView addGestureRecognizer:self.panGestureInHeaderView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIScrollView *)scrollViewWithSubViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(scrollableSubViewInSubViewController:)]) {
        return [(id<CCScrollableHeaderTabViewControllerViewSource>)viewController scrollableSubViewInSubViewController:viewController];
    } else if ([viewController.view isKindOfClass:[UIScrollView class]]) {
        return (id)viewController.view;
    } else {
        return nil;
    }
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers != viewControllers) {
        [self removeChildViewControllersAndObservers];
        _viewControllers = viewControllers;
        
        CGSize size = _containerView.bounds.size;
        CGFloat headerOffset = _headerView ? _maxHeightOfHeaderView : 0.0;
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(headerOffset + CGRectGetHeight(_tabView.bounds),
                                                      0.0,
                                                      _containerView.contentInset.bottom,
                                                      0.0);
        
        // Resize sub view controllers
        NSUInteger count = _viewControllers.count;
        __block UIViewController *lastViewController = nil;
                [_containerView setContentSize:(CGSize){size.width * _viewControllers.count, 900.0}];
        [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
            vc.wantsFullScreenLayout = YES;
            vc.view.translatesAutoresizingMaskIntoConstraints = NO;
            UIScrollView *scrollView = [self scrollViewWithSubViewController:vc];
            if (scrollView) {
                [scrollView addObserver:self
                             forKeyPath:@"contentOffset"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
                
                if ([scrollView isKindOfClass:[UITableView class]]) {
                    [scrollView addObserver:self
                                 forKeyPath:@"tableHeaderView"
                                    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                    context:nil];
                }
            }
            [self addChildViewController:vc];
            [_containerView addSubview:vc.view];
            [vc didMoveToParentViewController:self];
            
            if (idx == 0) {
                if (scrollView) {
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
                    [vc.view autoMatchDimension:ALDimensionHeight
                                    toDimension:ALDimensionHeight
                                         ofView:self.containerView];
                    scrollView.contentInset = contentInsets;
                }
                else {
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:contentInsets.top];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:contentInsets.bottom];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
                    [vc.view autoMatchDimension:ALDimensionHeight
                                    toDimension:ALDimensionHeight
                                         ofView:self.containerView
                                     withOffset:-(self.containerView.bounds.size.height - contentInsets.top)];
                    
                }
                [vc.view autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView];
            }
            else {
                if (scrollView) {
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
                    scrollView.contentInset = contentInsets;
                }
                else {
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:contentInsets.top];
                    [vc.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:contentInsets.bottom];
                }
                [vc.view autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:lastViewController.view];
                [vc.view autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:lastViewController.view];
            }
            
            if (idx == count - 1) {
                [vc.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
            }
            lastViewController = vc;
        }];
        [_containerView setContentSize:(CGSize){size.width * _viewControllers.count, 900.0}];
        _selectedIndex = 0;
    }
}

- (void)removeChildViewControllersAndObservers {
    for (UIViewController *vc in _viewControllers) {
        [vc willMoveToParentViewController:nil];
        UIScrollView *scrollView = [self scrollViewWithSubViewController:vc];
        if (scrollView) {
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            if ([scrollView isKindOfClass:[UITableView class]]) {
                [scrollView removeObserver:self
                                forKeyPath:@"tableHeaderView"];
            }
        }
        [vc removeFromParentViewController];
    }
}

- (void)layoutViewControllers
{
    CGSize size = _containerView.bounds.size;
    
    CGFloat headerOffset = _headerView ? _maxHeightOfHeaderView : 0.0;
    __block UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    // Resize sub view controllers
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        CGRect newFrame = (CGRect){size.width * idx, 0.0, size};
        UIScrollView *scrollView = [self scrollViewWithSubViewController:viewController];
        if (scrollView) {
            CGFloat h = size.height;
            CGFloat bottom = h - (_minHeightOfHeaderView + CGRectGetHeight(_tabView.bounds) + scrollView.contentSize.height);
            if (bottom > 0) {
                contentInsets = UIEdgeInsetsMake(headerOffset + CGRectGetHeight(_tabView.bounds), 0.0, bottom + _containerView.contentInset.bottom, 0.0);
                scrollView.contentInset = contentInsets;
                scrollView.showsVerticalScrollIndicator = NO;
            }
            else {
                contentInsets = UIEdgeInsetsMake(headerOffset + CGRectGetHeight(_tabView.bounds), 0.0, _containerView.contentInset.bottom, 0.0);
                scrollView.contentInset = contentInsets;
                scrollView.showsVerticalScrollIndicator = YES;
            }
            
            // Set scroll view indicator insets
            [scrollView setScrollIndicatorInsets:scrollView.contentInset];

            if (self.scrollToTop) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([self.class isEqualOrGreaterThanIOS7]) {
                        if (self.navigationController.isNavigationBarHidden) {
                            [scrollView setContentOffset:CGPointMake(0, -64) animated:NO];
                        }
                        else {
                            [scrollView setContentOffset:CGPointMake(0, -44) animated:NO];
                        }
                    }
                    else {
                        [scrollView setContentOffset:CGPointMake(0, -44) animated:NO];
                    }
                });
            }
        } else {
            //TODO:
            [viewController.view setFrame:UIEdgeInsetsInsetRect(newFrame, contentInsets)];
        }
    }];
    [_containerView setContentSize:(CGSize){size.width * _viewControllers.count, 0.0}];
}

- (UIViewController *)selectedViewController
{
    return _viewControllers[_selectedIndex];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutViewControllers];

    if (![self.class isEqualOrGreaterThanIOS8]) {
        //http://stackoverflow.com/questions/15490140/auto-layout-error
        [self.view layoutIfNeeded];
    }
    self.scrollToTop = NO;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (_selectedIndex != selectedIndex) {
        [self layoutSubViewControllerToSelectedViewController];
        [_containerView setContentOffset:(CGPoint){selectedIndex * CGRectGetWidth(_containerView.bounds), _containerView.contentOffset.y}
                                animated:animated];
        _selectedIndex = selectedIndex;
        [self.tabView setSelectedTabItemIndex:selectedIndex animated:animated];
    }
}

- (UIScrollView *)scrollViewWithSelectedViewController {
    return [self scrollViewWithSubViewController:self.selectedViewController];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - gesture
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIViewController *selectedViewController = self.selectedViewController;
    UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
    if (scrollView) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)panInHeaderView:(UIPanGestureRecognizer *)gesture {
    UIViewController *selectedViewController = self.selectedViewController;
    UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
    [scrollView pop_removeAnimationForKey:kPanDecelerateKey];
    [scrollView pop_removeAnimationForKey:kPanBounceKey];
    
    CGPoint tran = [gesture translationInView:self.headerView];
    if (UIGestureRecognizerStateBegan == [gesture state]){
        self.lastLocationWhenPanning = [gesture locationInView:self.headerView];
        self.startOffsetWhenPanning = scrollView.contentOffset;
    }
    else if (UIGestureRecognizerStateChanged == [gesture state]) {
        CGPoint currentLocation = [gesture locationInView:self.headerView];
        CGPoint tmpTran = CGPointMake(currentLocation.x - self.lastLocationWhenPanning.x,
                                      currentLocation.y - self.lastLocationWhenPanning.y);
        if (CGPointEqualToPoint(tmpTran, CGPointZero)) {
            return;
        }
        else if (fabs(tmpTran.x) <= fabs(tmpTran.y) || tmpTran.x == 0) {   //up or down
            CGPoint offset = self.startOffsetWhenPanning;
            CGFloat kMaxoffset = self.maxHeightOfHeaderView - self.minHeightOfHeaderView;
            if (tmpTran.y > 0) {   //down
                if (!self.headerViewTopContraint.constant) {   //to the max headerView
                    return;
                }
                
                offset.y = MAX(offset.y - tran.y, -scrollView.contentInset.top);
            }
            else {   //up
                if (fabs(fabs(self.headerViewTopContraint.constant) - kMaxoffset) < 0.001) { //min height
                    return;
                }
                
                offset.y = MIN(offset.y - tran.y, -(scrollView.contentInset.top - kMaxoffset));
            }
            [scrollView setContentOffset:offset animated:NO];
        }
        self.lastLocationWhenPanning = currentLocation;
    }
    else {
        CGPoint currentLocation = [gesture locationInView:self.headerView];
        CGPoint tmpTran = CGPointMake(currentLocation.x - self.lastLocationWhenPanning.x,
                                      currentLocation.y - self.lastLocationWhenPanning.y);
        if (fabs(tmpTran.x) <= fabs(tmpTran.y) || tmpTran.x == 0) {   //up or down
            BOOL needDecay = self.headerViewTopContraint.constant && fabs(scrollView.contentOffset.y) < scrollView.contentInset.top;
            //            NSLog(@"needDecay=%d", needDecay);
            if (needDecay) {
                CGPoint velocity = [gesture velocityInView:self.headerView];
                velocity.x = 0.0;
                
                velocity.x = -velocity.x;
                velocity.y = -velocity.y;
                
                POPDecayAnimation *decayAnimation = [POPDecayAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
                decayAnimation.velocity = [NSValue valueWithCGPoint:velocity];
                [scrollView pop_addAnimation:decayAnimation forKey:kPanDecelerateKey];
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CCSimpleTabView
- (void)simpleTabView:(CCSimpleTabView *)simpleTabView didSelectedTabItemAtIndex:(NSInteger)index {
    [self setSelectedIndex:index animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UIViewController *selectedViewController = [self selectedViewController];
    if ([keyPath isEqualToString:@"contentOffset"]) {
        UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
        if (scrollView != object) {
            return;
        }
        
        if (scrollView.isDragging) {
            [scrollView pop_removeAnimationForKey:kPanDecelerateKey];
        }
        
        [scrollView pop_removeAnimationForKey:kPanBounceKey];  //防止正在panInHeaderView的bounce时，从下发的scrollView触发scroll的影响
        POPDecayAnimation *decayAnimation = [scrollView pop_animationForKey:kPanDecelerateKey];
        if (decayAnimation) {
            CGFloat kMaxoffset = self.maxHeightOfHeaderView - self.minHeightOfHeaderView;
            if (!self.headerViewTopContraint.constant && fabs(scrollView.contentOffset.y) > scrollView.contentInset.top) {  //max height
                POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
                springAnimation.velocity = decayAnimation.velocity;
                springAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -scrollView.contentInset.top)];
                springAnimation.springBounciness = 0.0;
                springAnimation.springSpeed = 5.0;
                [scrollView pop_addAnimation:springAnimation forKey:kPanBounceKey];
                [scrollView pop_removeAnimationForKey:kPanDecelerateKey];
            }
            else if (fabs(fabs(self.headerViewTopContraint.constant) - kMaxoffset) < 0.001 &&
                     fabs(scrollView.contentOffset.y) < scrollView.contentInset.top - kMaxoffset)     //min height
            {   //min height
                POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
                springAnimation.velocity = decayAnimation.velocity;
                springAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -(scrollView.contentInset.top - kMaxoffset))];
                springAnimation.springBounciness = 0.0;
                springAnimation.springSpeed = 5.0;
                [scrollView pop_addAnimation:springAnimation forKey:kPanBounceKey];
                [scrollView pop_removeAnimationForKey:kPanDecelerateKey];
            }
        }
        [self layoutHeaderViewAndTabBar];
    }
    else if ([keyPath isEqualToString:@"tableHeaderView"]) {
        UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
        if (scrollView != object) {
            return;
        }
       
        self.scrollToTop = NO;
        if ([selectedViewController respondsToSelector:@selector(shouldScrollToTopWhenTableHeaderViewChange)]) {
            self.scrollToTop = [(id<CCScrollableHeaderTabViewControllerViewSource>)selectedViewController shouldScrollToTopWhenTableHeaderViewChange];
        }
    }
}

- (void)layoutHeaderViewAndTabBar
{
    UIViewController *selectedViewController = self.selectedViewController;
    
    // Get selected scroll view.
    UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
    
    if (scrollView) {
        // Set header view frame
        CGFloat headerViewHeight = 0;
        if (self.scrollToTop) {
            headerViewHeight = _minHeightOfHeaderView;
        }
        else {
            headerViewHeight = _maxHeightOfHeaderView - (scrollView.contentOffset.y + scrollView.contentInset.top);
            headerViewHeight = MAX(headerViewHeight, _minHeightOfHeaderView);
            headerViewHeight = MIN(headerViewHeight, _maxHeightOfHeaderView);
        }
        
        self.headerViewTopContraint.constant = headerViewHeight - self.headerView.bounds.size.height;
      
        if ([self respondsToSelector:@selector(headerViewDidScrollWithOffsetY:)]) {
            [self headerViewDidScrollWithOffsetY:(headerViewHeight - _minHeightOfHeaderView)];
        }
    } else {
        // Set header view frame
        self.headerViewTopContraint.constant = _maxHeightOfHeaderView + _containerView.contentInset.top;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Scroll view delegate (tab view controllers)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self layoutSubViewControllerToSelectedViewController];
}

- (void)layoutSubViewControllerToSelectedViewController
{
    UIViewController *selectedViewController = [self selectedViewController];
    // Define selected scroll view
    UIScrollView *selectedScrollView = [self scrollViewWithSubViewController:selectedViewController];
    if (!selectedScrollView) {
        return;
    }
    
    // Define relative y calculator
    CGFloat (^calcRelativeY)(CGFloat contentOffsetY, CGFloat contentInsetTop) = ^CGFloat(CGFloat contentOffsetY, CGFloat contentInsetTop) {
        return _maxHeightOfHeaderView - _minHeightOfHeaderView - (contentOffsetY + contentInsetTop);
    };
    
    // Adjustment offset or frame for sub views.
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if (selectedViewController == viewController) {
            return;
        }
        
        UIScrollView *targetScrollView = [self scrollViewWithSubViewController:viewController];
        if ([targetScrollView isKindOfClass:[UIScrollView class]]) {
            // Scroll view
            // -> Adjust offset
            CGFloat relativePositionY = calcRelativeY(selectedScrollView.contentOffset.y, selectedScrollView.contentInset.top);
            if (relativePositionY > 0) {
                // The header view's height is higher than minimum height.
                // -> Adjust same offset.
                [targetScrollView setContentOffset:selectedScrollView.contentOffset];
                
            } else {
                // The header view height is lower than minimum height.
                // -> Adjust top of scrollview, If target header view's height is higher than minimum height.
                CGFloat targetRelativePositionY = calcRelativeY(targetScrollView.contentOffset.y, targetScrollView.contentInset.top);
                if (targetRelativePositionY > 0) {
                    targetScrollView.contentOffset = (CGPoint){
                        targetScrollView.contentOffset.x,
                        -(CGRectGetHeight(_tabView.bounds) + _minHeightOfHeaderView - _containerView.contentInset.top)
                    };
                }
            }
        } else {
            // Not scroll view
            // -> Adjust frame to area at the bottom of tab bar.
            //            CGFloat y = CGRectGetMaxY(_tabBar.frame) - _containerView.contentInset.top;
            //            [targetScrollView setFrame:(CGRect){
            //                CGRectGetMinX(targetScrollView.frame), y,
            //                CGRectGetMinX(targetScrollView.frame), CGRectGetHeight(_containerView.frame) - y
            //            }];
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isDragging) {
        NSUInteger numberOfViewControllers = _viewControllers.count;
        NSInteger newSelectedIndex = round(scrollView.contentOffset.x / scrollView.contentSize.width * numberOfViewControllers);
        newSelectedIndex = MIN(numberOfViewControllers - 1, MAX(0, newSelectedIndex));
        self.tabView.selectedTabItemIndex = newSelectedIndex;
        _selectedIndex = newSelectedIndex;
    }
}

@end
