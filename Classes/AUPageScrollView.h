//
//  AUPageScrollView.h
//
//  Created by Emil Wojtaszek on 25.11.2011.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

//Frameworks
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol AUPageScrollViewDelegate;
@protocol AUPageScrollViewDataSource;

typedef enum {
    AUScrollHorizontalDirection     = 0,
    AUScrollVerticalDirection       = 1
} AUScrollDirection;

extern NSString* AUPageScrollViewDidChangePageNotification;
extern NSString* AUPageScrollViewTagKey;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUPageScrollView : UIView <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
@protected
    // scroll view
    UIScrollView *_scrollView;
    
    // objects communications
    __unsafe_unretained id<AUPageScrollViewDelegate> _delegate;
    __unsafe_unretained id<AUPageScrollViewDataSource> _dataSource;
    
    // contain all pages, if page is unloaded then page is respresented as [NSNull null]
    NSMutableArray* _pages;
    
    //scroll direction, default AUScrollHorizontalDirection
    AUScrollDirection _scrollDirection;
    
    NSUInteger _pageCount;
    NSInteger _selectedPageIndex;

    UIEdgeInsets _loadInset;    
    UIEdgeInsets _appearanceInset;
@private
    
    NSInteger _indexOfFirstLoadedPage;
    NSInteger _indexOfLastLoadedPage;

    NSInteger _indexOfFirstVisiblePage;
    NSInteger _indexOfLastVisiblePage;
    NSInteger _currentPageIndex;

    BOOL _startChangingPageIndex;
    NSInteger _lastPageIndex;
    
    BOOL _rotationInProgress;
    NSUInteger _pageIndexBeforeRotation;
}

@property (nonatomic, unsafe_unretained) id<AUPageScrollViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<AUPageScrollViewDataSource> dataSource;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) NSMutableArray* pages;
@property (nonatomic, assign) AUScrollDirection scrollDirection;
@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;

/*
 * Init with proper frame and scroll direction.
 * Page size is the same as scroll view size
 */
- (id)initWithFrame:(CGRect)frame scrollDirection:(AUScrollDirection)scrollDirection;

/*
 * Clean array of pages, load from dataSource all visibla pages.
 * Must be invoke at least once, to show content
 */
- (void)reloadData;

/*
 * Just reload visibla pages (it's mean thar reload pages in _scrollView bounds)
 * Must be invoke at least once, to show content
 */
- (void)reloadVisiblePages;

/*
 * Return page at index, if NSNull then return nil
 */
- (UIView*) pageAtIndex:(NSUInteger)index;

/*
 * Layout all pages
 */
- (void)layoutPages;

- (void) loadBoundaryPages;
- (void) unloadUnnecessaryPages;
/*
 * Load page at given index (if page is not loaded)
 */
- (UIView *)loadPageAtIndex:(NSInteger)index;

/*
 * Unload page at index or indexes
 */
- (void)unloadPageAtIndex:(NSInteger)index;
- (void)unloadPageAtIndexes:(NSIndexSet*)indexSet;

/*
 * Unload all invisable pages
 */
- (void) unloadInvisiblePages;

/*
 * Unload all pages
 */
- (void) unloadAllPages;

/*
 * Scroll to wanted page
 */
- (void) scrollToPageIndex:(NSUInteger)index animated:(BOOL)animated;

/*
 * Handling View Rotations
 */
- (void)willAnimateRotationWithDuration:(NSTimeInterval)duration;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

@protocol AUPageScrollViewDataSource <NSObject>
@required
/*
 * Return view for proper index
 */
- (UIView*) pageScrollView:(AUPageScrollView*)pageScrollView pageAtIndex:(NSInteger)index;
/*
 * Retun number of pages to show
 */
- (NSInteger) numberOfPagesInPageScrollView:(AUPageScrollView*)pageScrollView;

@optional
/*
 * Default, return page view
 */
- (UIView*) selectionResponsibleViewInPageScrollView:(AUPageScrollView*)pageScrollView forPageView:(UIView*)page;
@end

@protocol AUPageScrollViewDelegate <NSObject>
@optional
/*
 * Retun page size at index, if not defined page size is equal to view size
 */
- (CGSize) pageScrollView:(AUPageScrollView*)pageScrollView pageSizeAtIndex:(NSUInteger)index;

- (void) pageScrollViewDidChangePage:(AUPageScrollView*)pageScrollView previousPageIndex:(NSUInteger)index;
- (void) pageScrollView:(AUPageScrollView*)pageScrollView didSelectPageAtIndex:(NSUInteger)index;

/*
 * Methods called while reloadData.
 */
- (void) pageScrollViewStartReloadingData:(AUPageScrollView*)pageScrollView;
- (void) pageScrollViewFinishReloadingData:(AUPageScrollView*)pageScrollView;

/*
 * Methods called when page get in/out of _scrollView bounds
 */
- (void) pageScrollView:(AUPageScrollView*)pageScrollView pageDidAppearAtIndex:(NSUInteger)index;
- (void) pageScrollView:(AUPageScrollView*)pageScrollView pageDidDisappearAtIndex:(NSUInteger)index;

/*
 * Visible or unvisible page can be loaded/unloaded (read _loadInset)
 */
- (void) pageScrollView:(AUPageScrollView*)pageScrollView willLoadPage:(UIView*)page atIndex:(NSUInteger)index;
- (void) pageScrollView:(AUPageScrollView*)pageScrollView willUnloadPage:(UIView*)page atIndex:(NSUInteger)index;

- (void) pageScrollView:(AUPageScrollView*)pageScrollView didLoadPage:(UIView*)page atIndex:(NSUInteger)index;
- (void) pageScrollView:(AUPageScrollView*)pageScrollView didUnloadPage:(UIView*)page atIndex:(NSUInteger)index;

/*
 * Tell when scrollView did start/stop dragging
 */
- (void) pageScrollViewWillBeginDragging:(AUPageScrollView*)pageScrollView;
- (void) pageScrollViewDidEndDragging:(AUPageScrollView*)pageScrollView;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUPageScrollView (Calculation)
- (BOOL) pageExistAtIndex:(NSInteger)index;
- (void) sendAppearanceDelegateMethodsIfNeeded;

- (CGSize)scrollContentSize;
- (NSUInteger)currentPageIndex;
- (NSUInteger)indexOfPageContainsPoint:(CGPoint)point;
- (NSInteger)firstVisiblePageIndex;
- (NSInteger)firstVisiblePageIndexWithInset:(UIEdgeInsets)inset;
- (NSInteger)lastVisiblePageIndex;
- (NSInteger)lastVisiblePageIndexWithInset:(UIEdgeInsets)inset;
- (NSInteger)visiblePagesCount;
- (NSInteger)visiblePagesCountWithInset:(UIEdgeInsets)inset;

- (NSRange)visiblePagesRange;
- (NSRange)visiblePagesRangeWithInset:(UIEdgeInsets)inset;

- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGPoint)originForPageAtIndex:(NSUInteger)index;
- (CGSize)pageSizeAtIndex:(NSUInteger)index;

- (NSArray*)visiblePages;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUPageScrollView (Delegates)
- (void) pageScrollViewStartReloadingData;
- (void) pageScrollViewFinishReloadingData;
- (void) pageScrollViewDidChangePage:(NSUInteger)previousIndex;

- (void) pageDidAppearAtIndex:(NSUInteger)index;
- (void) pageDidDisappearAtIndex:(NSUInteger)index;

- (void) willLoadPage:(UIView*)page atIndex:(NSUInteger)index;
- (void) willUnloadPage:(UIView*)page atIndex:(NSUInteger)index;

- (void) didLoadPage:(UIView*)page atIndex:(NSUInteger)index;
- (void) didUnloadPage:(UIView*)page atIndex:(NSUInteger)index;

- (void) didSelectPageAtIndex:(NSUInteger)index;
- (void) didDeselectPageAtIndex:(NSUInteger)index;

- (void) willBeginDragging;
- (void) didEndDragging;
@end

