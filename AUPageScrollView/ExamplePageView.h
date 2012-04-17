//
//  ExamplePageView.h
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 17.04.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//Frameworks
#import <Foundation/Foundation.h>

//AUPageScrollView
#import "AUPageView.h"

@interface ExamplePageView : AUPageView {
    UILabel* _label;
}

- (void) setPageIndex:(NSUInteger)index;

@end
