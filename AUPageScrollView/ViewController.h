//
//  ViewController.h
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 17.04.2012.
//  Copyright (c) 2012 AppUnite.com. All rights reserved.
//

#import <UIKit/UIKit.h>

//Example
#import "ExamplePageView.h"
#import "ExamplePageScrollView.h"

@interface ViewController : UIViewController <AUPageScrollViewDataSource, AUReusablePageScrollViewDelegate> {
    ExamplePageScrollView* _pageScrollView;
}

@end
