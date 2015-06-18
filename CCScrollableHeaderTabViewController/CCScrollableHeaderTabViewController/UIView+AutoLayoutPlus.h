//
//  UIView+AutoLayoutPlus.h
//  CC901iPhone
//
//  Created by user on 14-3-10.
//  Copyright (c) 2014年 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PureLayout.h>

@interface UIView (AutoLayoutPlus)
- (NSArray *)constaintsForAttribute:(NSLayoutAttribute)attribute;
- (NSLayoutConstraint *)constraintForAttribute:(NSLayoutAttribute)attribute;

- (NSLayoutConstraint *)constraintForAttribute:(NSInteger)attribute toView:(UIView *)view;
- (void)removeAllEdgeConstaintsToView:(UIView *)toView;
@end
