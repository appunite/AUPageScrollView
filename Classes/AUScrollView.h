//
//  AUScrollView.h
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 19.06.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//Framework
#import <UIKit/UIKit.h>

@interface AUScrollView : UIScrollView

/*
 * Container of all subview.
 */
@property (nonatomic, strong) UIView* intermediateView;

@end
