//
//  ViewController.m
//  AUPageScrollView
//
//  Created by Emil Wojtaszek on 17.04.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect rect = self.view.bounds;
    
    // create page scroll view
    _pageScrollView = [[ExamplePageScrollView alloc] initWithFrame:rect 
                                                      scrollDirection:AUScrollHorizontalDirection];
    _pageScrollView.delegate = self;
    _pageScrollView.dataSource = self;
    [self.view addSubview:_pageScrollView];
    
    // reload data
    [_pageScrollView reloadData];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - AUPageScrollViewDataSource

- (UIView*) pageScrollView:(ExamplePageScrollView*)pageScrollView pageAtIndex:(NSInteger)index {
    
    // check if has any pages to reuse
    ExamplePageView* page = (ExamplePageView*)[pageScrollView dequeueReusablePage];
    
    // if not, create new
    if (!page) {
        page = [[ExamplePageView alloc] init];
    }
    
    // set proper title and color of page
    [page setPageIndex:index];
    
    return page;
}

- (NSInteger) numberOfPagesInPageScrollView:(AUPageScrollView*)pageScrollView {
    return 10;
}

@end
