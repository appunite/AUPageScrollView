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
//Selection
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@end

@interface AUPageView : UIView <AUPageViewDelegate> {
@private
    BOOL _selected;
}

@property (nonatomic, assign) BOOL selected;

@end
