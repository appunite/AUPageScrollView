//
//  AUScrollView.m
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 19.06.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AUScrollView.h"

@implementation AUScrollView
@synthesize intermediateView = _intermediateView;

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)initialize {
    // set up view
    [self setBackgroundColor:[UIColor clearColor]];
    [self setShowsHorizontalScrollIndicator:YES];
    [self setBounces: YES];
    [self setDirectionalLockEnabled: YES];
    [self setMultipleTouchEnabled:NO];
    [self setPagingEnabled:YES];        
    [self setDecelerationRate: UIScrollViewDecelerationRateFast];
    [self setScrollsToTop: NO];
    [self setAutoresizingMask:
     UIViewAutoresizingFlexibleWidth | 
     UIViewAutoresizingFlexibleHeight];
    
    // intermidiate view containing all subviews
    _intermediateView = [[UIView alloc] init];
    [self addSubview:_intermediateView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    return [self initWithFrame:CGRectZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setContentSize:(CGSize)contentSize {
    // set content size of scrollView
    [super setContentSize:contentSize];
    
    // calculate rect of contentView
    CGRect contentRect = CGRectMake(0.0f, 0.0f, MAX(contentSize.width, CGRectGetWidth(self.bounds)), MAX(contentSize.height, CGRectGetHeight(self.bounds)));
    _intermediateView.frame = contentRect;
    
    // make view visible
    [self bringSubviewToFront:_intermediateView];
}

@end
