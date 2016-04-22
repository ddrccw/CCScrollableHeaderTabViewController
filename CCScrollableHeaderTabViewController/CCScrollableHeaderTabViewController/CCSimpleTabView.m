//
//  CCSimpleTabView.m
//
//
//  Created by ddrccw on 14-6-20.
//
//

#import "CCSimpleTabView.h"

static const int kTabItemTagOffset = 0x100;

@interface CCSimpleTabItem ()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *badgeView;
@property (nonatomic, assign) CCSimpleTabItemType type;
@end

@implementation CCSimpleTabItem

- (instancetype)init {
    if (self = [super init]) {
        _type = CCSimpleTabItemTypeAutoResize;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                        image:(UIImage *)image
             highlightedImage:(UIImage *)highlightedImage
{
    if (self = [self init]) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        _iconImageView = [[UIImageView alloc] initWithImage:image
                                           highlightedImage:highlightedImage];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_iconImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:_iconImageView];
        
        _badgeView = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *badgeImage = [[UIImage imageNamed:@"num_pad"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 9, 0, 9)];
        [_badgeView setBackgroundImage:badgeImage forState:UIControlStateNormal];
        _badgeView.hidden = YES;
        [self addSubview:_badgeView];
        
        if (!([title isEqual:[NSNull null]] || !title || !title.length)) {
            _titleLabel = [[UILabel alloc] init];
            _titleLabel.text = title;
            _titleLabel.font = font;
            _titleLabel.textColor = color;
            _titleLabel.highlightedTextColor = highlightedColor;
            _titleLabel.textAlignment = NSTextAlignmentCenter;
            _titleLabel.backgroundColor = [UIColor clearColor];
            [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:_titleLabel];
            [_titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_titleLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-3];
            
            [_iconImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:20];
            [_iconImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:8];
            [_iconImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_titleLabel withOffset:-3];
            [_iconImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        }
        else {
            [_iconImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_iconImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        }
        
        [_badgeView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:_iconImageView withOffset:-9];
        [_badgeView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_iconImageView withOffset:-9];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                        image:(UIImage *)image
             highlightedImage:(UIImage *)highlightedImage
{
    return [self initWithTitle:title
                          font:[UIFont systemFontOfSize:12]
                         color:RGB(3, 3, 3)
              highlightedColor:[UIColor lightGrayColor]
                         image:image highlightedImage:highlightedImage];
}

- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                      padding:(CGFloat)padding
{
    if (self = [self init]) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        _titleLabel.font = font;
        [_titleLabel setHighlightedTextColor:highlightedColor];
        [_titleLabel setTextColor:color];
        [_titleLabel sizeToFit];
        if (padding > 0) {
            _type = CCSimpleTabItemTypeFixWidth;
            self.bounds = (CGRect){
                .origin = CGPointZero,
                .size = CGSizeMake(_titleLabel.bounds.size.width + padding * 2, _titleLabel.bounds.size.height)
            };
            [self autoSetDimension:ALDimensionWidth toSize:self.bounds.size.width];
        }
        else {
            _type = CCSimpleTabItemTypeAutoResize;
        }
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:_titleLabel];
        [_titleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, padding, 0, padding)];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
{
    if (self = [self initWithTitle:title
                              font:font
                             color:color
                  highlightedColor:highlightedColor
                           padding:0])
    {
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                      padding:(CGFloat)padding
{
    if (self = [self initWithTitle:title
                              font:[UIFont systemFontOfSize:15]
                             color:color
                  highlightedColor:highlightedColor
                           padding:padding])
    {
    }
    return self;
    
}

- (instancetype)initWithTitle:(NSString *)title
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
{
    return [self initWithTitle:title
                          font:[UIFont systemFontOfSize:15]
                         color:color
              highlightedColor:highlightedColor];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.titleLabel.highlighted = selected;
    self.iconImageView.highlighted = selected;
    if (!selected) {
        if (!self.defaultBackgroundColor) {
            self.backgroundColor = RGB(230, 230, 230);
        }
        else {
            self.backgroundColor = self.defaultBackgroundColor;
        }
    }
    else {
        if (!self.selectedBackgroundColor) {
            self.backgroundColor = RGB(215, 215, 215);
        }
        else {
            self.backgroundColor = self.selectedBackgroundColor;
        }
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSInteger, CCSimpleTabViewLayoutType) {
    CCSimpleTabViewLayoutTypeAutoResizeItem,
    CCSimpleTabViewLayoutTypeFixWidthItem
};

@interface CCSimpleTabView ()
@property (strong, nonatomic) NSArray<CCSimpleTabItem *> *tabItems;
@property (strong, nonatomic) NSArray *proportions;
@property (assign, nonatomic) CGFloat sumOfproportions;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *indicatorImageView;
@property (strong, nonatomic) NSLayoutConstraint *indicatorLeadingConstraint;
@property (assign, nonatomic) CCSimpleTabViewLayoutType layoutType;
@end

@implementation CCSimpleTabView

- (void)setup {
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.backgroundColor = RGB(230, 230, 230);
    
    _containerView = [UIView new];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView.backgroundColor = [UIColor clearColor];
    [self addSubview:_containerView];
    [_containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    _scrollView = [UIScrollView new];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.bounces = NO;
    
    _scrollView.scrollEnabled = YES;
    
    [_containerView addSubview:_scrollView];
    [_scrollView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    _indicatorImageView = [[UIImageView alloc] init];
    _indicatorImageView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTabInsets:(UIEdgeInsets)insets {
    if (self = [self init]) {
        self.tabInsets = insets;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (CGFloat)normalizedProportionOfTabItemAtIndex:(NSInteger)index {
    NSNumber *p = self.proportions[index];
    return p.floatValue / self.sumOfproportions;
}

- (NSInteger)numberOfTabItems {
    return self.tabItems.count;
}

- (void)setTabItems:(NSArray<CCSimpleTabItem *> *)tabItems {
    NSMutableArray *proportions = [NSMutableArray arrayWithCapacity:tabItems.count];
    NSInteger i = 0;
    while (i < tabItems.count) {
        [proportions addObject:@1];
        ++i;
    }
    [self setTabItems:tabItems proportions:[NSArray arrayWithArray:proportions]];
}

- (void)setTabItems:(NSArray<CCSimpleTabItem *> *)tabItems proportions:(NSArray *)proportions {
    NSAssert(tabItems.count == proportions.count, @"tabItems.count should be equal to proportions.count");
    if (_tabItems != tabItems) {
        _tabItems = tabItems;
        _proportions = proportions;
        _sumOfproportions = 0;
        for (NSNumber *p in _proportions) {
            _sumOfproportions += p.floatValue;
        }
        [self reloadScrollView];
    }
}

- (void)setTabInsets:(UIEdgeInsets)tabInsets {
    if (!UIEdgeInsetsEqualToEdgeInsets(_tabInsets, tabInsets)) {
        _tabInsets = tabInsets;
        [self removeAllEdgeConstaintsToView:_containerView];
        [_containerView autoPinEdgesToSuperviewEdgesWithInsets:tabInsets];
        [self reloadScrollView];
    }
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    if (_indicatorImage != indicatorImage) {
        _indicatorImage = indicatorImage;
        _indicatorImageView.image = indicatorImage;
        [_indicatorImageView sizeToFit];
        [self relocateIndicator];
        [self layoutIfNeeded];
    }
}

- (void)relocateIndicator {
    if (self.tabItems.count) {
        [self.indicatorLeadingConstraint autoRemove];
        
        CGFloat offset = 0;
        offset = self.selectedTabItem.center.x - self.indicatorImageView.bounds.size.width / 2;
        self.indicatorLeadingConstraint = [self.indicatorImageView autoPinEdge:ALEdgeLeading
                                                                        toEdge:ALEdgeLeading
                                                                        ofView:self.scrollView
                                                                    withOffset:offset];
    }
}

- (void)reloadScrollView {
    _layoutType = CCSimpleTabViewLayoutTypeAutoResizeItem;
    [self removeMenuItems];
    [self addMenuItems];
    
    _selectedTabItemIndex = NSIntegerMax;
    [self setSelectedTabItemIndex:0 animated:NO];
}

- (void)removeMenuItems {
    NSArray *views = [self.scrollView subviews];
    for (UIView *v in views) {
        if (v.tag >= kTabItemTagOffset) {
            [self.scrollView removeAllEdgeConstaintsToView:v];
            [v removeFromSuperview];
        }
    }
}

- (void)addMenuItems {
    CCSimpleTabItem *tabItem = nil;
    CCSimpleTabItem *lastTabItem = nil;
    NSUInteger count = [self.tabItems count];
    CGFloat width = 0;
    
    for (NSInteger i = 0; i < count; ++i) {
        tabItem = self.tabItems[i];
        tabItem.tag = kTabItemTagOffset + i;
        [tabItem addTarget:self
                    action:@selector(menuItemPressed:)
          forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:tabItem];
        CGFloat proportion = [self normalizedProportionOfTabItemAtIndex:i];
        if (i == 0) {
            [tabItem autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
            [tabItem autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
            [tabItem autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
            if (tabItem.type == CCSimpleTabItemTypeAutoResize) {
                [tabItem autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:proportion];
            }
            else {
                _layoutType = CCSimpleTabViewLayoutTypeFixWidthItem;
                width = tabItem.bounds.size.width;
            }
            [tabItem autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.containerView];
            
            if (i == count - 1) {
                [tabItem autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
                proportion = [self normalizedProportionOfTabItemAtIndex:0];
                CGFloat offset = 0;
                if (tabItem.type == CCSimpleTabItemTypeAutoResize) {
                    offset = (self.scrollView.bounds.size.width * proportion) / 2 - self.indicatorImageView.bounds.size.width / 2;
                }
                else {
                    self.scrollView.contentSize = CGSizeMake(width, self.containerView.bounds.size.height);
                    offset = (self.scrollView.contentSize.width * proportion) / 2 - self.indicatorImageView.bounds.size.width / 2;
                }
                
                [_scrollView addSubview:_indicatorImageView];
                self.indicatorImageView.tag = count + kTabItemTagOffset;
                [self.indicatorImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.scrollView];
                self.indicatorLeadingConstraint = [self.indicatorImageView autoPinEdge:ALEdgeLeading
                                                                                toEdge:ALEdgeLeading
                                                                                ofView:self.scrollView
                                                                            withOffset:offset];
            }
        }
        else {
            [tabItem autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:lastTabItem];
            [tabItem autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:lastTabItem];
            [tabItem autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:lastTabItem];
            if (tabItem.type == CCSimpleTabItemTypeAutoResize) {
                [tabItem autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:proportion];
            }
            else {
                width += tabItem.bounds.size.width;
            }
            if (i == count - 1) {
                [tabItem autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
                proportion = [self normalizedProportionOfTabItemAtIndex:0];
                CGFloat offset = 0;
                if (tabItem.type == CCSimpleTabItemTypeAutoResize) {
                    offset = (self.scrollView.bounds.size.width * proportion) / 2 - self.indicatorImageView.bounds.size.width / 2;
                }
                else {
                    self.scrollView.contentSize = CGSizeMake(width, self.containerView.bounds.size.height);
                    offset = (self.scrollView.contentSize.width * proportion) / 2 - self.indicatorImageView.bounds.size.width / 2;
                }
                
                [_scrollView addSubview:_indicatorImageView];
                self.indicatorImageView.tag = count + kTabItemTagOffset;
                [self.indicatorImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.scrollView];
                self.indicatorLeadingConstraint = [self.indicatorImageView autoPinEdge:ALEdgeLeading
                                                                                toEdge:ALEdgeLeading
                                                                                ofView:self.scrollView
                                                                            withOffset:offset];
            }
        }
        tabItem.selected = (!i) ? YES: NO;
        lastTabItem = tabItem;
    }
}

- (void)menuItemPressed:(CCSimpleTabItem *)menuItem {
    NSInteger idx = menuItem.tag - kTabItemTagOffset;
    if (self.selectedTabItemIndex != idx) {
        self.selectedTabItemIndex = idx;
        if ([self.delegate respondsToSelector:@selector(simpleTabView:didSelectedTabItemAtIndex:)]) {
            [self.delegate simpleTabView:self didSelectedTabItemAtIndex:idx];
        }
    }
}

- (void)setSelectedTabItemIndex:(NSInteger)selectedTabItemIndex {
    [self setSelectedTabItemIndex:selectedTabItemIndex animated:YES];
}

- (void)setSelectedTabItemIndex:(NSInteger)selectedTabItemIndex animated:(BOOL)animated{
    if (selectedTabItemIndex >= self.tabItems.count) return;
    
    if (_selectedTabItemIndex != selectedTabItemIndex) {
        CCSimpleTabItem *fromTabItem = (CCSimpleTabItem *)[self.scrollView viewWithTag:kTabItemTagOffset + _selectedTabItemIndex];
        if (fromTabItem) {
            [fromTabItem setSelected:NO];
        }
        
        CCSimpleTabItem *toTabItem = (CCSimpleTabItem *)[self.scrollView viewWithTag:kTabItemTagOffset + selectedTabItemIndex];
        [toTabItem setSelected:YES];
        _selectedTabItemIndex = selectedTabItemIndex;
        self.selectedTabItem = toTabItem;
        
        [self.scrollView scrollRectToVisible:toTabItem.frame animated:animated];
        if (animated) {
            [UIView animateWithDuration:.2 animations:^{
                [self relocateIndicator];
                [self layoutIfNeeded];
            } completion:nil];
        }
        else {
            [self relocateIndicator];
            [self layoutIfNeeded];
        }
    }
}

@end
