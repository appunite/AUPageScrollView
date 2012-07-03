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
        [self setPagingEnabled:YES];
    }
    return self;
}

//- (void)pageScrollViewStartReloadingData {
//    [super pageScrollViewStartReloadingData];
//    NSLog(@"pageScrollViewStartReloadingData");
//}

//- (void)pageScrollViewFinishReloadingData {
//    [super pageScrollViewFinishReloadingData];
//    NSLog(@"pageScrollViewFinishReloadingData");
//}

//- (void)pageScrollViewDidChangePage:(NSInteger)previousIndex {
//    [super pageScrollViewDidChangePage:previousIndex];   
//    NSLog(@"pageScrollViewDidChangePage: %i", previousIndex);
//}

//- (void)pageDidAppearAtIndex:(NSInteger)index {
//    [super pageDidAppearAtIndex:index];
//    NSLog(@"pageDidAppearAtIndex: %i", index);
//}

//- (void)pageDidDisappearAtIndex:(NSInteger)index {
//    [super pageDidAppearAtIndex:index];
//    NSLog(@"pageDidDisappearAtIndex: %i", index);
//}

//- (void)didLoadPage:(UIView*)page atIndex:(NSInteger)index {
//    [super didLoadPage:page atIndex:index];
//    NSLog(@"didLoadPage:atIndex: %i", index);
//}

//- (void)didUnloadPage:(UIView*)page atIndex:(NSInteger)index {
//    [super didUnloadPage:page atIndex:index];
//    NSLog(@"didUnloadPage:atIndex: %i", index);
//}

//- (void)didSelectPageAtIndex:(NSInteger)index {
//    [super didSelectPageAtIndex:index];
//    NSLog(@"didSelectPageAtIndex: %i", index);
//}

//- (void)didDeselectPageAtIndex:(NSInteger)index {
//    [super didDeselectPageAtIndex:index];
//    NSLog(@"didDeselectPageAtIndex: %i", index);
//}

//- (void)pageScrollView:(AUPageScrollView*)pageScrollView didSelectPageAtIndex:(NSInteger)index {
//    [super didDeselectPageAtIndex:index];
//    NSLog(@"pageScrollView:didSelectPageAtIndex: %i", index);
//}

@end
