//
//  CCSimpleTabView.h
//
//
//  Created by ddrccw on 14-6-20.
//
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CCSimpleTabItemBatchTypeNumbered = 0,
    CCSimpleTabItemBatchTypeMarked = 1,
} CCSimpleTabItemBatchType;


typedef NS_ENUM(NSInteger, CCSimpleTabItemType) {
    CCSimpleTabItemTypeAutoResize,
    CCSimpleTabItemTypeFixWidth
};

@interface CCSimpleTabItem : UIControl


@property (nonatomic, strong) UILabel *titleLabel;
@property (strong, nonatomic) UIColor *defaultBackgroundColor;
@property (strong, nonatomic) UIColor *selectedBackgroundColor;
@property (nonatomic, assign, readonly) CCSimpleTabItemType type;

- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                        image:(UIImage *)image
             highlightedImage:(UIImage *)highlightedImage;

//         ----------------------------
//  item   |<-padding--label--pading->|
//         ----------------------------
- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                      padding:(CGFloat)padding;
- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor;
- (instancetype)initWithTitle:(NSString *)title
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                      padding:(CGFloat)padding;
- (instancetype)initWithTitle:(NSString *)title
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor;
@end

@class CCSimpleTabView;
@protocol CCSimpleTabViewDelegate <NSObject>

- (void)simpleTabView:(CCSimpleTabView *)simpleTabView didSelectedTabItemAtIndex:(NSInteger)index;

@end

//IMPOTANT：不同type的item不能混用
@interface CCSimpleTabView : UIView

@property (weak, nonatomic) id<CCSimpleTabViewDelegate> delegate;
@property (assign, nonatomic) NSInteger selectedTabItemIndex;
@property (weak, nonatomic) CCSimpleTabItem *selectedTabItem;
@property (assign, nonatomic) UIEdgeInsets tabInsets;
@property (strong, nonatomic) UIImage *indicatorImage;



- (instancetype)initWithTabInsets:(UIEdgeInsets)insets;
/**
 *  need to be call before other setters
 *
 *  @param tabItems    tabItems
 *  @param proportions tabItem的宽度计算比重，仅对CCSimpleTabItemTypeAutoResize类型起作用
 */
- (void)setTabItems:(NSArray<CCSimpleTabItem *> *)tabItems proportions:(NSArray *)proportions;
- (void)setTabItems:(NSArray<CCSimpleTabItem *> *)tabItems;  //need to be call before other setters
- (NSInteger)numberOfTabItems;
- (void)setSelectedTabItemIndex:(NSInteger)selectedTabItemIndex animated:(BOOL)animated;

@end