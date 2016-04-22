//
//  CCScrollableHeaderTabViewController.m
//  Edu901iPhone
//
//  Created by ddrccw on 15-1-5.
//  Copyright (c) 2015年 user. All rights reserved.
//

#import "CCScrollableHeaderTabViewController.h"
#import <objc/runtime.h>
#import <POP.h>
#import <KVOController/FBKVOController.h>

static NSString * const kPanDecelerateKey = @"decelerate";
static NSString * const kPanBounceKey = @"bounce";
static NSInteger kMaxNumberOfCacheViewController = 3;

static const char kScrollObserverKey;

////////////////////////////////////////////////////////////////////////////////
@interface UITableView (CCScrollableHeaderTabViewControllerPrivate)
@end

@implementation UITableView (CCScrollableHeaderTabViewControllerPrivate)

+ (void)load
{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(reloadData);
        SEL swizzledSelector = @selector(cc_reloadData);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)cc_reloadData {
    CGPoint offset = CGPointZero;
    if (self.scrollObserver) {
        offset = self.contentOffset;
        [self removeObserverForContentOffset];
    }
    
    [self cc_reloadData];
    
    if (self.scrollObserver) {
        self.contentOffset = offset;
        [self addObserverForContentOffset];
    }
}

@end

@implementation UIScrollView (CCScrollableHeaderTabViewController)

- (void)setScrollObserver:(CCScrollableHeaderTabViewController *)scrollObserver {
    objc_setAssociatedObject(self, &kScrollObserverKey, scrollObserver, OBJC_ASSOCIATION_ASSIGN);
}

- (CCScrollableHeaderTabViewController *)scrollObserver {
    return objc_getAssociatedObject(self, &kScrollObserverKey);
}

- (void)addObserverForContentOffset {
    if (self.scrollObserver) {
        __weak __typeof__(self) weakSelf = self;
        [self.scrollObserver.KVOController observe:self
                                           keyPath:@"contentOffset"
                                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                             block:^(id observer, id object, NSDictionary *change)
         {
             __strong __typeof__(self) self = weakSelf;
             [self.scrollObserver observeValueForKeyPath:@"contentOffset" ofObject:object change:change context:nil];
         }];
    }
}

- (void)removeObserverForContentOffset {
    if (self.scrollObserver) {
        [self.scrollObserver.KVOController unobserve:self keyPath:@"contentOffset"];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
@interface CCScrollableHeaderTabViewController ()
<UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL fixLayoutProblemLessThenIOS8_;
}
@property (strong, nonatomic, readwrite) NSArray *placeHolderViews;
@property (strong, nonatomic, readwrite) NSArray *viewControllers;
@property (strong, nonatomic, readwrite) NSMutableArray *cachedviewControllers;

@property (strong, nonatomic) UIPanGestureRecognizer *panGestureInHeaderView;
@property (assign, nonatomic) CGPoint lastLocationWhenPanning;
@property (assign, nonatomic) CGPoint startOffsetWhenPanning;
@property (assign, nonatomic) CGPoint endOffsetWhenPanning;
@property (strong, nonatomic) FBKVOController *KVOController;
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
    CGRect rect = self.view.bounds;
    if (!CGSizeEqualToSize(rect.size, [UIScreen mainScreen].bounds.size)) {
        rect.size = [UIScreen mainScreen].bounds.size;
        self.view.bounds = rect;
        [self.view layoutIfNeeded];
    }

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
    self.headerView.clipsToBounds = YES;
    
    self.KVOController = [FBKVOController controllerWithObserver:self];
    self.cachedviewControllers = [NSMutableArray arrayWithCapacity:kMaxNumberOfCacheViewController];
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
        [self.placeHolderViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
            [self removeChildViewControllerAndObserverAtIndex:idx];
            [self.containerView removeAllEdgeConstaintsToView:view];
            [view removeConstraints:view.constraints];
            [view removeFromSuperview];
        }];
        [_containerView setContentOffset:CGPointZero
                                animated:NO];
        _viewControllers = viewControllers;
        
        CGSize size = _containerView.bounds.size;
        CGFloat headerOffset = _headerView ? _maxHeightOfHeaderView : 0.0;
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(headerOffset + CGRectGetHeight(_tabView.bounds),
                                                      0.0,
                                                      _containerView.contentInset.bottom,
                                                      0.0);
        
        // Resize sub view controllers
        NSUInteger count = _viewControllers.count;
        NSMutableArray *placeHolderViews = [NSMutableArray arrayWithCapacity:count];
//        __block UIViewController *lastViewController = nil;
        __block UIView *lastPlaceHolderView = nil;

        [_containerView setContentSize:(CGSize){size.width * count, 900.0}];
        [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
            vc.wantsFullScreenLayout = YES;
#endif
            UIView *placeHolderView = [[UIView alloc] init];
            placeHolderView.backgroundColor = [UIColor clearColor];
            placeHolderView.translatesAutoresizingMaskIntoConstraints = NO;
            [placeHolderViews addObject:placeHolderView];
            [_containerView addSubview:placeHolderView];
           
            if (idx == 0) {
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
                [placeHolderView autoMatchDimension:ALDimensionHeight
                                        toDimension:ALDimensionHeight
                                             ofView:self.containerView];
                [placeHolderView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView];
            }
            else {
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
                [placeHolderView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:lastPlaceHolderView];
                [placeHolderView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:lastPlaceHolderView];
            }
            
            if (idx < kMaxNumberOfCacheViewController) {
                BOOL isViewLoaded = [vc isViewLoaded];
                if (!isViewLoaded) {
                    [vc.view layoutIfNeeded];
                }
                UIScrollView *scrollView = [self scrollViewWithSubViewController:vc];
                if (scrollView) {
                    scrollView.contentInset = contentInsets;
                    if (!self.scrollToTop) {
                        scrollView.contentOffset = CGPointMake(0, -contentInsets.top);
                    }
                }
                
                [self addChildViewController:vc intoPlaceHolderView:placeHolderView];
                [self addObserverForChildViewController:vc];
            }

            
            if (idx == count - 1) {
                [placeHolderView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
            }

            lastPlaceHolderView = placeHolderView;
        }];
        
        self.placeHolderViews = [NSArray arrayWithArray:placeHolderViews];
        _selectedIndex = 0;
    }
}

- (void)addObserverForChildViewController:(UIViewController *)childViewController {
    UIScrollView *scrollView = [self scrollViewWithSubViewController:childViewController];
    if (scrollView) {
        scrollView.scrollObserver = self;
        [scrollView addObserverForContentOffset];
        __weak __typeof__(self) weakSelf = self;
        [self.KVOController observe:scrollView
                            keyPath:@"tableHeaderView"
                            options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                              block:^(id observer, id object, NSDictionary *change)
         {
             __strong __typeof__(self) self = weakSelf;
             [self observeValueForKeyPath:@"tableHeaderView" ofObject:object change:change context:nil];
         }];
    }
}

- (void)addChildViewController:(UIViewController *)childViewController intoPlaceHolderView:(UIView *)placeHolderView {
    childViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:childViewController];
    [placeHolderView addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
    [childViewController.view autoPinEdgesToSuperviewEdges];
    [self.cachedviewControllers addObject:childViewController];
}

- (void)addChildViewControllerAndObserverAtIndex:(NSInteger)index {
    UIViewController *addingVC = self.viewControllers[index];
    UIView *placeHolderView = self.placeHolderViews[index];
    [self addChildViewController:addingVC intoPlaceHolderView:placeHolderView];
    [self addObserverForChildViewController:addingVC];
}

- (void)removeObserverForChildViewController:(UIViewController *)childViewController {
    UIScrollView *scrollView = [self scrollViewWithSubViewController:childViewController];
    if (scrollView) {
        [self.KVOController unobserve:scrollView keyPath:@"tableHeaderView"];
        [scrollView removeObserverForContentOffset];
        scrollView.scrollObserver = nil;
    }
}

- (void)removeChildViewControllerAndObserverAtIndex:(NSInteger)index {
    UIViewController *removingVC = self.viewControllers[index];
    UIView *placeHolderView = self.placeHolderViews[index];
    [removingVC willMoveToParentViewController:nil];
    [self removeObserverForChildViewController:removingVC];
    [removingVC.view removeFromSuperview];
    [placeHolderView removeAllEdgeConstaintsToView:removingVC.view];
    [removingVC removeFromParentViewController];
    [self.cachedviewControllers removeObject:removingVC];
}

- (void)removeChildViewControllersAndObservers {
    [self.viewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeChildViewControllerAndObserverAtIndex:idx];
    }];
}

- (void)relayoutCachedViewControllersWithSelectedIndex:(NSInteger)selectedIndex {
    if (self.viewControllers.count <= kMaxNumberOfCacheViewController) {
        return;
    }
    
    NSInteger half = (kMaxNumberOfCacheViewController % 2) == 0 ? kMaxNumberOfCacheViewController / 2 : (kMaxNumberOfCacheViewController + 1) / 2;
    
    NSInteger lastLeftBoundIndex = MAX(0, _selectedIndex - half);
    NSInteger lastRightBoundIndex = MIN(lastLeftBoundIndex + kMaxNumberOfCacheViewController - 1, self.viewControllers.count - 1);
    NSInteger leftBoundIndex = MAX(0, selectedIndex - half);
    NSInteger rightBoundIndex = MIN(leftBoundIndex + kMaxNumberOfCacheViewController - 1, self.viewControllers.count - 1);

    if (leftBoundIndex == lastLeftBoundIndex && rightBoundIndex == lastRightBoundIndex) {
        return;
    }
    
    // 无交叉
    if ((leftBoundIndex > lastRightBoundIndex) ||
        (rightBoundIndex < lastLeftBoundIndex))
    {
        for (NSInteger i = lastLeftBoundIndex; i <= lastRightBoundIndex; ++i) {
            [self removeChildViewControllerAndObserverAtIndex:i];
        }

        for (NSInteger i = leftBoundIndex; i <= rightBoundIndex; ++i) {
            [self addChildViewControllerAndObserverAtIndex:i];
        }
    }
    // 交叉， selectedIndex > _selectedIndex
    else if(leftBoundIndex <= lastRightBoundIndex &&
            lastRightBoundIndex <= rightBoundIndex)
    {
        for (NSInteger i = lastLeftBoundIndex; i < leftBoundIndex; ++i) {
            [self removeChildViewControllerAndObserverAtIndex:i];
        }

        for (NSInteger i = lastRightBoundIndex + 1; i <= rightBoundIndex; ++i) {
            [self addChildViewControllerAndObserverAtIndex:i];
        }
    }
    else {
        for (NSInteger i = rightBoundIndex + 1; i <= lastRightBoundIndex; ++i) {
            [self removeChildViewControllerAndObserverAtIndex:i];
        }

        for (NSInteger i = leftBoundIndex; i < lastLeftBoundIndex; ++i) {
            [self addChildViewControllerAndObserverAtIndex:i];
        }
    }
}

- (void)layoutViewControllers
{
    CGSize size = _containerView.bounds.size;
    
    CGFloat headerOffset = _headerView ? _maxHeightOfHeaderView : 0.0;
    __block UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    // Resize sub view controllers
    [_cachedviewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
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
        [self relayoutCachedViewControllersWithSelectedIndex:selectedIndex];
        [self layoutSubViewControllerToSelectedViewController];
        [_containerView setContentOffset:(CGPoint){selectedIndex * CGRectGetWidth(_containerView.bounds), _containerView.contentOffset.y}
                                animated:animated];
        _selectedIndex = selectedIndex;
        [self.tabView setSelectedTabItemIndex:selectedIndex animated:animated];
        if ([self respondsToSelector:@selector(scrollableHeaderTabViewController:didSelectTabAtIndex:)]) {
            [self scrollableHeaderTabViewController:self didSelectTabAtIndex:selectedIndex];
        }
    }
}

- (UIScrollView *)scrollViewWithSelectedViewController {
    return [self scrollViewWithSubViewController:self.selectedViewController];
}

- (void)setHeaderViewTopContraintWithValue:(CGFloat)value {
    CGFloat lastOffsetYOfHeaderView = self.headerViewTopContraint.constant;
    self.headerViewTopContraint.constant = value;
    UIScrollView *scrollView = [self scrollViewWithSubViewController:self.selectedViewController];
    
    if (scrollView) {
        CGFloat offsetY = self.maxHeightOfHeaderView + value + CGRectGetHeight(_tabView.bounds);
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -offsetY) animated:NO];
        if ([self respondsToSelector:@selector(headerViewDidScrollWithOffsetY:scrollDirection:)]) {
            if (lastOffsetYOfHeaderView > value) {
                [self headerViewDidScrollWithOffsetY:lastOffsetYOfHeaderView - value
                                     scrollDirection:CCScrollableHeaderScrollDirectionUp];
            }
            else {
                [self headerViewDidScrollWithOffsetY:value - lastOffsetYOfHeaderView
                                     scrollDirection:CCScrollableHeaderScrollDirectionDown];
            }
        }
    } else {
        //TODO:
    }

}

- (CGFloat)estimateHeaderViewTopContraint {
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
        
//        CGFloat top = headerViewHeight - self.headerView.bounds.size.height;
//        NSLog(@"est top=%@ scroll offset=%@, contenInset=%@", @(top), NSStringFromCGPoint(scrollView.contentOffset), NSStringFromUIEdgeInsets(scrollView.contentInset));
        return headerViewHeight - self.headerView.bounds.size.height;
    }
    else {
        return _maxHeightOfHeaderView + _containerView.contentInset.top;
    }
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
    [self setSelectedIndex:index animated:NO];
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
        
        CGPoint oldOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
        CGPoint newOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
//        NSLog(@"oo=%@, no=%@", NSStringFromCGPoint(oldOffset), NSStringFromCGPoint(newOffset));
        
        CCScrollableHeaderScrollDirection direction = CCScrollableHeaderScrollDirectionUnknown;
        if (fabs(newOffset.y - oldOffset.y) < 1e-6) {
            direction = CCScrollableHeaderScrollDirectionUnknown;
        }
        else if ((newOffset.y - oldOffset.y) > 0) {
            direction = CCScrollableHeaderScrollDirectionUp;
        }
        else {
            direction = CCScrollableHeaderScrollDirectionDown;
        }
        [self layoutHeaderViewAndTabBarWithScrollDirection:direction];
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

- (void)layoutHeaderViewAndTabBarWithScrollDirection:(CCScrollableHeaderScrollDirection)scrollDirection
{
    UIViewController *selectedViewController = self.selectedViewController;
    // Get selected scroll view.
    UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
    if (scrollView) {
        CGFloat top = [self estimateHeaderViewTopContraint];
        self.headerViewTopContraint.constant = top;
        CGFloat headerViewHeight = top + self.headerView.bounds.size.height;
        if ([self respondsToSelector:@selector(headerViewDidScrollWithOffsetY:scrollDirection:)]) {
            [self headerViewDidScrollWithOffsetY:(headerViewHeight - _minHeightOfHeaderView)
                                 scrollDirection:scrollDirection];
        }
    } else {
        // Set header view frame
        self.headerViewTopContraint.constant = [self estimateHeaderViewTopContraint];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Scroll view delegate (tab view controllers)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self layoutSubViewControllerToSelectedViewController];
}

/**
 *  切换tab，重新基于header的位置，layout sub vc
 */
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
    [_cachedviewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
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
        if (_selectedIndex != newSelectedIndex && [self respondsToSelector:@selector(scrollableHeaderTabViewController:didSelectTabAtIndex:)]) {
            [self scrollableHeaderTabViewController:self didSelectTabAtIndex:newSelectedIndex];
        }
        
        if (_selectedIndex != newSelectedIndex) {
            [self relayoutCachedViewControllersWithSelectedIndex:newSelectedIndex];
        }
        _selectedIndex = newSelectedIndex;
    }
}

@end
