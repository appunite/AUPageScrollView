//
//  AUReusablePageScrollView.h
//
//  Created by Emil Wojtaszek on 12.11.2011.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

//Frameworks
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//Others
#import "AUPageScrollView.h"

@protocol AUReusablePageScrollViewDelegate;

@interface AUReusablePageScrollView : AUPageScrollView {
@private
    NSMutableSet *_recycledPages;
}

/*
 * Dequeue reusable page, nil if none
 */
- (UIView *)dequeueReusablePage;
- (void) reloadPageAtIndex:(NSUInteger)index;

/*
 * Delegates reimplementation
 */
- (void) setDelegate:(id<AUReusablePageScrollViewDelegate>)delegate;
- (id<AUReusablePageScrollViewDelegate>)delegate;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol AUReusablePageScrollViewDelegate <AUPageScrollViewDelegate>
@optional
- (void)pageScrollView:(AUPageScrollView *)pageScrollView didRecyclePage:(UIView*)page;
- (void)pageScrollView:(AUPageScrollView *)pageScrollView didDequeuePage:(UIView*)page;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUReusablePageScrollView (Delegates)
- (void) didRecyclePage:(UIView*)page;
- (void) didDequeuePage:(UIView*)page;
@end
