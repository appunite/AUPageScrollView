//
//  AUReusablePageScrollView.h
//
//  Created by Emil Wojtaszek on 12.11.2011.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

#import "AUReusablePageScrollView.h"

@interface AUReusablePageScrollView (Private)
- (void)recyclePage:(UIView *)page;
@end

@implementation AUReusablePageScrollView

#pragma mark -
#pragma mark Init

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _recycledPages = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Class methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)reloadPageAtIndex:(NSUInteger)index {
    [self unloadPageAtIndex:index];
    [self loadPageAtIndex:index];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutPages {
    [self loadBoundaryPages:NO];
    [self unloadUnnecessaryPages];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)dequeueReusablePage {
    UIView *result = [_recycledPages anyObject];
    if (result) {
        [_recycledPages removeObject:result];
        [self didDequeuePage:result];
    }
    return result;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didUnloadPage:(UIView *)page atIndex:(NSUInteger)index {
    [super didUnloadPage:page atIndex:index];
    // add page to recycled pages array
    [self recyclePage:page];
}

#pragma mark -
#pragma mark Calculation redefinition

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setDelegate:(id<AUReusablePageScrollViewDelegate>)delegate {
    [super setDelegate:delegate];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (id<AUReusablePageScrollViewDelegate>)delegate {
    return (id<AUReusablePageScrollViewDelegate>)[super delegate];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUReusablePageScrollView (Private)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)recyclePage:(UIView *)page {
    // recycle page
    [_recycledPages addObject:page];
    // remove from super view
    [page removeFromSuperview];
    // send delegate
    [self didRecyclePage:page];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUReusablePageScrollView (Delegates)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didRecyclePage:(UIView*)page {
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:didRecyclePage:)]) {
        [[self delegate] pageScrollView:self didRecyclePage:page];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didDequeuePage:(UIView*)page {
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:didDequeuePage:)]) {
        [[self delegate] pageScrollView:self didDequeuePage:page];
    }
}

@end
