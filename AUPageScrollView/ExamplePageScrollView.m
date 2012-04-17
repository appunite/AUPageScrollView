//
//  ExamplePageScrollView.m
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 17.04.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExamplePageScrollView.h"

@implementation ExamplePageScrollView

- (id)initWithFrame:(CGRect)frame scrollDirection:(AUScrollDirection)scrollDirection {
    self = [super initWithFrame:frame scrollDirection:scrollDirection];
    if (self) {
        [_scrollView setPagingEnabled:YES];
    }
    return self;
}

@end
