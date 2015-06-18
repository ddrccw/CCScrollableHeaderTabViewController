//
//  CCSimpleTabView.h
//
//
//  Created by ddrccw on 14-6-20.
//
//

#import <UIKit/UIKit.h>
#import "NSString+Utility.h"

@interface CCSimpleTabItem : UIControl
@property (strong, nonatomic) UIColor *defaultBackgroundColor;
@property (strong, nonatomic) UIColor *selectedBackgroundColor;

- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor
                        image:(UIImage *)image
             highlightedImage:(UIImage *)highlightedImage;
//- (instancetype)initWithTitle:(NSString *)title
//                        image:(UIImage *)image
//             highlightedImage:(UIImage *)highlightedImage;
- (instancetype)initWithTitle:(NSString *)title
                         font:(UIFont *)font
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor;
- (instancetype)initWithTitle:(NSString *)title
                        color:(UIColor *)color
             highlightedColor:(UIColor *)highlightedColor;
@end

@class CCSimpleTabView;
@protocol CCSimpleTabViewDelegate <NSObject>

- (void)simpleTabView:(CCSimpleTabView *)simpleTabView didSelectedTabItemAtIndex:(NSInteger)index;

@end

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
 *  @param proportions tabItem的宽度计算比重
 */
- (void)setTabItems:(NSArray *)tabItems proportions:(NSArray *)proportions;
- (void)setTabItems:(NSArray *)tabItems;  //need to be call before other setters
- (NSInteger)numberOfTabItems;
- (void)setSelectedTabItemIndex:(NSInteger)selectedTabItemIndex animated:(BOOL)animated;
@end