//
//  AUPageView.h
//
//  Created by Emil Wojtaszek on 28.01.2012.
//  Copyright (c) 2012 AppUnite.com. All rights reserved.
//

//Frameworks
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol AUPageViewDelegate <NSObject>
@optional
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (UITapGestureRecognizer *)selectionTapGestureRecognizer;
@end

@interface AUPageView : UIView <AUPageViewDelegate>
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) UITapGestureRecognizer* tapGestureRecognizer;
@end
