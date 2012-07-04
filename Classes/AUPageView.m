//
//  AUPageView.m
//
//  Created by Emil Wojtaszek on 28.01.2012.
//  Copyright (c) 2012 AppUnite.com. All rights reserved.
//

#import "AUPageView.h"

@implementation AUPageView
@synthesize selected = _selected;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    return [self initWithFrame:CGRectZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSelected:(BOOL)selected {
    [self setSelected:selected animated:NO];
}

#pragma mark -
#pragma mark AUPageViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    _selected = selected;   
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITapGestureRecognizer *)selectionTapGestureRecognizer {
    return _tapGestureRecognizer;    
}

@end
