//
//  ExamplePageView.m
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 17.04.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExamplePageView.h"

@implementation ExamplePageView

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] init];
        [_label setTextAlignment:UITextAlignmentCenter];
        [_label setBackgroundColor:[UIColor clearColor]];
        [_label setFont:[UIFont boldSystemFontOfSize:26.0f]];
        [_label setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self addSubview:_label];
    }
    return self;
}

- (void) setPageIndex:(NSUInteger)index {

    // set bg color
    if (index % 2 == 0) {
        [self setBackgroundColor:[UIColor redColor]];
    } else {
        [self setBackgroundColor:[UIColor blueColor]];
    }
    
    // set title
    NSString* title = [NSString stringWithFormat:@"%i", index];
    [_label setText:title];    
}

@end
