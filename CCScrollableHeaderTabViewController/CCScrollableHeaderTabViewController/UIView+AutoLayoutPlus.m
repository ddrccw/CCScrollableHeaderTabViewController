//
//  UIView+AutoLayoutPlus.m
//  CC901iPhone
//
//  Created by user on 14-3-10.
//  Copyright (c) 2014年 user. All rights reserved.
//

#import "UIView+AutoLayoutPlus.h"

@implementation UIView (AutoLayoutPlus)

- (NSArray *)constaintsForAttribute:(NSLayoutAttribute)attribute {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    NSArray *filteredArray = [[self constraints] filteredArrayUsingPredicate:predicate];
    
    return filteredArray;
}


- (NSLayoutConstraint *)constraintForAttribute:(NSLayoutAttribute)attribute {
    NSArray *constraints = [self constaintsForAttribute:attribute];
    
    if (constraints.count) {
        return constraints[0];
    }
    
    return nil;
}

- (NSLayoutConstraint *)constraintForAttribute:(NSInteger)attribute toView:(UIView *)view {
    NSArray *constraints = [self constaintsForAttribute:attribute];
    for (NSLayoutConstraint *constraint in constraints) {
        if (constraint.firstItem == view || constraint.secondItem == view) {
            return constraint;
        }
    }
    return nil;
}

- (void)removeAllEdgeConstaintsToView:(UIView *)toView {
    [[self constraintForAttribute:ALEdgeLeading
                           toView:toView] autoRemove];
    [[self constraintForAttribute:ALEdgeTrailing
                           toView:toView] autoRemove];
    [[self constraintForAttribute:ALEdgeTop
                           toView:toView] autoRemove];
    [[self constraintForAttribute:ALEdgeBottom
                           toView:toView] autoRemove];
    [[self constraintForAttribute:ALEdgeLeft
                           toView:toView] autoRemove];
    [[self constraintForAttribute:ALEdgeRight
                           toView:toView] autoRemove];
}
@end
