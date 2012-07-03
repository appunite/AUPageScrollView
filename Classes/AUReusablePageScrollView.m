//
//  AUReusablePageScrollView.h
//
//  Created by Emil Wojtaszek on 12.11.2011.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

#import "AUReusablePageScrollView.h"

@interface AUReusablePageScrollView (Private)
- (void)recyclePage:(UIView *)page;
- (NSMutableSet *)recycledPages;
@end

@implementation AUReusablePageScrollView

#pragma mark -
#pragma mark Init

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    return [self initWithFrame:CGRectZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _recycledPages = [[NSMutableSet alloc] init];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
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
    UIView *result = [[self recycledPages] anyObject];
    if (result) {
        [[self recycledPages] removeObject:result];
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

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setDataSource:(id<AUReusablePageScrollViewDataSource>)dataSource {
    [super setDataSource:dataSource];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (id<AUReusablePageScrollViewDataSource>)dataSource {
    return (id<AUReusablePageScrollViewDataSource>)[super dataSource];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUReusablePageScrollView (Private)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)recyclePage:(UIView *)page {
    // recycle page
    [[self recycledPages] addObject:page];
    // remove from super view
    [page removeFromSuperview];
    // send delegate
    [self didRecyclePage:page];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableSet *)recycledPages {
    id<AUReusablePageScrollViewDataSource> dataSource = self.dataSource;
    
    if ([dataSource respondsToSelector:@selector(recycledPagesForPageScrollView:)]) {
        
        NSMutableSet* recycledPages = [dataSource recycledPagesForPageScrollView:self];
        if (recycledPages) {
            return [dataSource recycledPagesForPageScrollView:self];
        }
    }
    
    if (!_recycledPages) {
        _recycledPages = [[NSMutableSet alloc] init];
    }
    return _recycledPages;
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
