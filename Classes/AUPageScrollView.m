//
//  AUPageScrollView.m
//
//  Created by Emil Wojtaszek on 25.11.2011.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

#import "AUPageScrollView.h"
#import "AUPageView.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUPageScrollView (Private)
- (void) cleanFlags;
- (void) tapGestureAction:(UITapGestureRecognizer*)gestureRecognizer;
- (UIView *)loadPageAtIndex:(NSInteger)index forceLoad:(BOOL)forceLoad;
@end

NSString* AUPageScrollViewDidChangePageNotification = @"AUPageScrollViewDidChangePageNotification";
NSString* AUPageScrollViewTagKey = @"kAUPageScrollViewTagKey";

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUPageScrollView

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize scrollDirection = _scrollDirection;
@synthesize scrollEnabled;
@synthesize scrollView = _scrollView;
@synthesize pages = _pages;

#pragma mark -
#pragma mark Dealloc

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    _delegate = nil;
    _dataSource = nil;
}

#pragma mark -
#pragma mark Inits

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // clean flags
        [self cleanFlags];
        
        //create array
        _pages = [[NSMutableArray alloc] init];
        
        // create scrollView
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds]; 
        [_scrollView setDelegate: self];

        [_scrollView setBackgroundColor:[UIColor clearColor]];
        [_scrollView setShowsHorizontalScrollIndicator:YES];
        
        [_scrollView setBounces: YES];
        [_scrollView setDirectionalLockEnabled: YES];
        [_scrollView setMultipleTouchEnabled:NO];
        [_scrollView setPagingEnabled:YES];        
        [_scrollView setDecelerationRate: UIScrollViewDecelerationRateFast];
        [_scrollView setScrollsToTop: NO];
        [_scrollView setAutoresizingMask:
         UIViewAutoresizingFlexibleWidth | 
         UIViewAutoresizingFlexibleHeight];
        
        [self addSubview: _scrollView];
        
        _loadInset = UIEdgeInsetsZero;
        
        _scrollDirection = AUScrollHorizontalDirection;
        _selectedPageIndex = -1;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id) initWithFrame:(CGRect)frame scrollDirection:(AUScrollDirection)scrollDirection {
    self = [self initWithFrame:frame];
    if (self) {
        _scrollDirection = scrollDirection;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    // calculate content size
    CGSize contentSize = [self scrollContentSize];
    [_scrollView setContentSize:contentSize];
}

#pragma mark -
#pragma mark Getters & setters

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setScrollEnabled:(BOOL)enabled {
    [_scrollView setScrollEnabled:enabled];    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) isScrollEnabled:(BOOL)enabled {
    return [_scrollView isScrollEnabled];
}

#pragma mark -
#pragma mark Getters & setters

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) ssetScrollDirection:(AUScrollDirection)scrollDirection {
    if (scrollDirection != _scrollDirection) {
        _scrollDirection = scrollDirection;
        [_scrollView setContentOffset:CGPointZero];
        [_scrollView setContentSize:CGSizeZero];
        [_pages removeAllObjects];
        [self cleanFlags];
    }
}

#pragma mark -
#pragma mark Class methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) reloadData {
    // send delegate methods
    [self pageScrollViewStartReloadingData];
    
    // remove all pages from view and _pages array
    [self unloadAllPages];
    
    // get page count
    _pageCount = [_dataSource numberOfPagesInPageScrollView:self];
    
    // create array of pages
	_pages = [[NSMutableArray alloc] initWithCapacity:_pageCount];
	
	// Fill our pages collection with empty placeholders
	for (int i = 0; i < _pageCount; i++) 
		[_pages addObject:[NSNull null]];
    
    // calculate content size
    CGSize contentSize = [self scrollContentSize];
    [_scrollView setContentSize:contentSize];
	
	// Load first visible pages
    UIEdgeInsets inset = _loadInset;
    NSRange range = [self visiblePagesRangeWithInset:inset];
    
    for (NSUInteger i=0; i<range.length; i++) {
        [self loadPageAtIndex:i + range.location];
    }
    
    //send delegate method
    [self pageScrollViewFinishReloadingData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)reloadVisiblePages {
	// Load first visible pages
    NSRange range = [self visiblePagesRange];
    
    for (NSUInteger i=range.location; i<range.length+range.location; i++) {
        if (![self pageAtIndex:i]) {
            [self loadPageAtIndex:i forceLoad:YES];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) reloadCurrentPage {
//    // get current page index
//    NSUInteger index = [self currentPageIndex];
//
//    // remove view from super view
//    [[self pageAtIndex:index] removeFromSuperview];
//    
//    // replace in array of pages
//    [_pages replaceObjectAtIndex:index withObject:[NSNull null]];
//    
//    // load page
//    [self loadPageAtIndex:index];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) pageAtIndex:(NSUInteger)index {
    // return nil if page doesn't exist
    if (![self pageExistAtIndex:index]) return nil;
    // get object from array
    id item = [_pages objectAtIndex:index];
    // return page if is not NSNull
    return (item == [NSNull null]) ? nil : item;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) loadBoundaryPages {
    // get load inset
    UIEdgeInsets loadInset = _loadInset;

    // calculate first visible page
    NSInteger firstPage = [self firstVisiblePageIndexWithInset:loadInset];

    // calculate last visible page
    NSInteger lastPage = [self lastVisiblePageIndexWithInset:loadInset];

    for (NSUInteger i=firstPage; i<=lastPage; i++) {
        [self loadPageAtIndex:i];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadUnnecessaryPages {
    // prepare variables
    UIEdgeInsets inset = _loadInset;
    NSUInteger firstVisiblePageIndexWithInset = [self firstVisiblePageIndexWithInset:inset];
    NSUInteger lastVisiblePageIndexWithInset = [self lastVisiblePageIndexWithInset:inset];

    // create insex set to return
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];

    // find pages to unload
    for (NSUInteger index = 0; index < _pageCount; index++) {
        id item = [_pages objectAtIndex:index];

        if (item != [NSNull null]) {
            if ((index < firstVisiblePageIndexWithInset) || (index > lastVisiblePageIndexWithInset)) {
                [indexSet addIndex:index];
            }
        }
    }
    
    // unload pages
    [self unloadPageAtIndexes:indexSet];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutPages {
    [self loadBoundaryPages];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)loadPageAtIndex:(NSInteger)index {
    return [self loadPageAtIndex:index forceLoad:NO];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadPageAtIndex:(NSInteger)index {

    if (![self pageExistAtIndex: index]) return;

    id page = [_pages objectAtIndex:index];
    
    // check if page is loaded
    if (page != [NSNull null]) {

        // send message to delegate
        [self willUnloadPage:page atIndex:index];        
        
        // remove from superview
        [page removeFromSuperview];
        
        // send message to delegate
        [self didUnloadPage:page atIndex:index];        
        
        // replace with null
        [_pages replaceObjectAtIndex:index withObject:[NSNull null]];
    }    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadPageAtIndexes:(NSIndexSet*)indexSet {
//    unsigned currentIndex = [indexSet firstIndex];
//    while (currentIndex != NSNotFound) {
////        NSLog(@"unloadPageAtIndex: %i", currentIndex);
//        [self unloadPageAtIndex:currentIndex];
//        currentIndex = [indexSet indexGreaterThanIndex: currentIndex];
//    }
    
    // enumarate insex set and unload page at index
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop) {
        [self unloadPageAtIndex:idx];
    }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadInvisiblePages {
    BOOL canUnload = YES;
    
    // get array of visible pages
    NSArray* visiblePages = [self visiblePages];
    
    // if visible page exist in array of pages then can't unload
    NSEnumerator* enumerator = [_pages reverseObjectEnumerator];

    for (id item in enumerator) {

        // avoid NSNull object
        if (item != [NSNull null]) {

            // enumerate all visible pages
            for (UIView* visiblePage in visiblePages) {
                
                if (item == visiblePage) {
                    canUnload = NO; break;
                }
            }

            // unload if can
            if (canUnload) {
                NSUInteger index = [_pages indexOfObject:item];
                [self unloadPageAtIndex:index];
            }
            
            // set flag to YES
            canUnload = YES;
        
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadAllPages {
    
    NSEnumerator* enumerator = [_pages reverseObjectEnumerator];
    // enumerate all pages
    for (id item in enumerator) {
        // check if item is UIView class
        if ([item isKindOfClass:[UIView class]]) {
            // remove view form superview
            [item removeFromSuperview];
            // replace that item with NSNull ibject
            NSUInteger index = [_pages indexOfObject:item];
            [_pages replaceObjectAtIndex:index withObject:[NSNull null]];
        }
    }
    
    // remove all pages
	[_pages removeAllObjects];

//    // enumarate all pages and unload
//    for (NSUInteger i=[_pages count]; i>0; i--) {
//        [self unloadPageAtIndex:i];
//    }
//    
//    // remove all pages
//	[_pages removeAllObjects];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) scrollToPageIndex:(NSUInteger)index animated:(BOOL)animated {
    // get origin of page at index
    CGPoint point = [self originForPageAtIndex:index];
    // set content offset
    [_scrollView setContentOffset:point animated:animated];
    
    // reload visible pages
    [self reloadVisiblePages];
    
    // invoke page did appera/disappear
    [self sendAppearanceDelegateMethodsIfNeeded];
}

#pragma mark -
#pragma mark Handling View Rotations

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // set rotation flag
    _rotationInProgress = YES;    
    _pageIndexBeforeRotation = [self currentPageIndex];
    
    // get current page
    id page = [self pageAtIndex:_pageIndexBeforeRotation];

    // send message
    if ([page respondsToSelector:@selector(willRotateToInterfaceOrientation:)]) {
        [page willRotateToInterfaceOrientation:orientation];
    }
    
    // unload invisible pages
    [self unloadUnnecessaryPages];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationWithDuration:(NSTimeInterval)duration {    
    // get current page
    id page = [self pageAtIndex:_pageIndexBeforeRotation];
    
    // send message
    if ([page respondsToSelector:@selector(willAnimateRotationWithDuration:)]) {
        [page willAnimateRotationWithDuration:duration];
    }

    // set up content offset
    CGRect frame = [self frameForPageAtIndex:_pageIndexBeforeRotation];
    _scrollView.contentOffset = frame.origin;

    // get visible pages range
    NSRange range = [self visiblePagesRangeWithInset:_loadInset];
    
    for (NSInteger i=range.location; i<=range.location + range.length - 1; i++) {
        if (page != [NSNull null]) {
            // get frame
            CGRect frame = [self frameForPageAtIndex:i];

            // get current page
            id page = [self pageAtIndex:i];
            
            // update frame, if can
            if (page != [NSNull null]) {
                [page setFrame:frame];
                
                if ([page isKindOfClass:[UIScrollView class]]) {
                    [page setContentSize:frame.size];
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    
    // get current page
    id page = [self pageAtIndex:_pageIndexBeforeRotation];
    
    // send message
    if ([page respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
        [page didRotateFromInterfaceOrientation:orientation];
    }

    // clear rotation flag
    _rotationInProgress = NO;
}

#pragma mark -
#pragma mark UIScrollView Delegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_rotationInProgress) return;
    
    // dont't call if no pages
    if ([_pages count] == 0) return;
    
    // calculate page indexes (fist and last loaded pages)
    UIEdgeInsets loadInset = _loadInset;
    NSUInteger firstLoadedPageIndex = [self firstVisiblePageIndexWithInset:loadInset];
    NSUInteger lastLoadedPageIndex = [self lastVisiblePageIndexWithInset:loadInset];

    if ((_indexOfFirstLoadedPage != firstLoadedPageIndex) || (_indexOfLastLoadedPage != lastLoadedPageIndex)) {
        
        // load boundary pages
        [self layoutPages];
        
        // save flags
        _indexOfFirstLoadedPage = firstLoadedPageIndex; _indexOfLastLoadedPage = lastLoadedPageIndex;
    }

    [self sendAppearanceDelegateMethodsIfNeeded];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (_startChangingPageIndex) {
        if (_currentPageIndex != _lastPageIndex) {
            [self pageScrollViewDidChangePage:_lastPageIndex]; 
            _startChangingPageIndex = NO;
        }
    }    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_startChangingPageIndex) {
        if (_currentPageIndex != _lastPageIndex) {
            [self pageScrollViewDidChangePage:_lastPageIndex]; 
            _startChangingPageIndex = NO;
        }
    }  
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self willBeginDragging];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self didEndDragging];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUPageScrollView (Calculation)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) pageExistAtIndex:(NSInteger)index {
    return (([_pages count] > 0) &&
            (index >= 0) && 
            (index <= [_pages count] - 1));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSUInteger) currentPageIndex {
    if (_scrollDirection == AUScrollHorizontalDirection) {
        return MIN(MAX(0, floorf((_scrollView.contentOffset.x + _scrollView.bounds.size.width * 0.5f) / _scrollView.bounds.size.width)), _pageCount);
    } else {
        return MIN(MAX(0, floorf((_scrollView.contentOffset.y + _scrollView.bounds.size.height * 0.5f) / _scrollView.bounds.size.height)), _pageCount);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)firstVisiblePageIndex {
    return [self firstVisiblePageIndexWithInset:UIEdgeInsetsZero];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) lastVisiblePageIndex {
    return [self lastVisiblePageIndexWithInset:UIEdgeInsetsZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)firstVisiblePageIndexWithInset:(UIEdgeInsets)inset {
    CGPoint contentOffset = CGPointMake(ceilf(_scrollView.contentOffset.x + inset.left), 
                                        ceilf(_scrollView.contentOffset.y + inset.top));    
    return [self indexOfPageContainsPoint:contentOffset];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)lastVisiblePageIndexWithInset:(UIEdgeInsets)inset {
    if (_pageCount == 0) return 0;
    
    // calculate farthest point
    CGPoint contentOffset = CGPointZero;
    if (_scrollDirection == AUScrollHorizontalDirection) {
        contentOffset = CGPointMake(floorf(_scrollView.contentOffset.x + _scrollView.bounds.size.width + inset.right) - 0.1f, // 0.1f - so that the last pixel does not belong to the next page
                                    floorf(_scrollView.contentOffset.y + inset.bottom));
        
    } else {
        contentOffset = CGPointMake(floorf(_scrollView.contentOffset.x + inset.right), 
                                    floorf(_scrollView.contentOffset.y + _scrollView.bounds.size.height + inset.bottom) - 0.1f);
    }
    
    // calculate last page index, and fram eof last page
    NSUInteger lastPageIndex = _pageCount -1;
    CGRect lastPageFrame = [self frameForPageAtIndex:lastPageIndex];
    
    // if calculated point is further than calculated point, return last page index
    if ((contentOffset.x + inset.left > lastPageFrame.origin.x) || (contentOffset.y + inset.top > lastPageFrame.origin.y)) {
        return lastPageIndex;
    }
    
    // find page with point
    return [self indexOfPageContainsPoint:contentOffset];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)visiblePagesCount {
    return [self visiblePagesCountWithInset:UIEdgeInsetsZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)visiblePagesCountWithInset:(UIEdgeInsets)inset {
    // find first and last visible page index
    NSUInteger indexOfFirstVisiblePage = [self firstVisiblePageIndexWithInset:inset];
    NSUInteger indexOfLastVisiblePage = [self lastVisiblePageIndexWithInset:inset];
    
    // calculate count of visible pages
    return indexOfLastVisiblePage - indexOfFirstVisiblePage + 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSUInteger) indexOfPageContainsPoint:(CGPoint)point {

    NSInteger index = 0;

    // if respond to selector then sum all pages to index
    if ([_delegate respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat originX = 0;
        CGFloat originY = 0;
        
        CGSize size = CGSizeZero;
        CGRect rect = CGRectZero;
        for (NSUInteger i=0; i<_pageCount; i++) {
            
            size = [_delegate pageScrollView:self pageSizeAtIndex:i];
            
            if (_scrollDirection == AUScrollHorizontalDirection) {
                rect = CGRectMake(originX, 0.0f, size.width, size.height);
            } else {
                rect = CGRectMake(0.0f, originY, size.width, size.height);
            }
            
            if (!CGRectContainsPoint(rect, point)) {
                originX += size.width;
                originY += size.height;
            } else {
                return MAX(0, i);
            }

//            originX += size.width;
//            originY += size.height;
        }
        
    } else { //if not respond then single page has frame of view
        if (_scrollDirection == AUScrollHorizontalDirection) {
            CGFloat contentOffset = point.x;
            index = floorf((contentOffset) / self.bounds.size.width);
        } else {
            CGFloat contentOffset = point.y;
            index = floorf((contentOffset) / self.bounds.size.height);
        }
    }
    
    return MAX(0, index);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray*) visiblePages {
    // calculate first visible page and visible page count
    NSRange range = [self visiblePagesRange];
    
    // create array
    NSMutableArray* array = [NSMutableArray array];
    
    for (NSInteger i=range.location; i<=range.length + range.location - 1; i++) {
        
        // check if page index is in bounds 
        if ([self pageExistAtIndex: i]) {
            // get page at index
            id item = [_pages objectAtIndex: i];
            
            // add page to array if could load
            if (item) {
                [array addObject: item];
            }
        }
    }
    
    // return array of visible pages
    return array;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSRange)visiblePagesRangeWithInset:(UIEdgeInsets)inset {
    // calculate first visible page and visible page count
    NSInteger firstVisiblePageIndex = [self firstVisiblePageIndexWithInset:inset];
    NSInteger visiblePagesCount = [self visiblePagesCountWithInset:inset];
    
    return NSMakeRange(firstVisiblePageIndex, visiblePagesCount);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSRange)visiblePagesRange {
    return [self visiblePagesRangeWithInset:UIEdgeInsetsZero];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize) scrollContentSize {

    // if respond to selector then sum all pages to index
    if ([_delegate respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat width = 0;
        CGFloat height = 0;
        
        for (NSUInteger i=0; i<_pageCount; i++) {
            CGSize size = [_delegate pageScrollView:self pageSizeAtIndex:i];
            width += size.width;
            height += size.height;
        }
        
        if (_scrollDirection == AUScrollHorizontalDirection) {
            return CGSizeMake(width, 0.0f);
        } else {
            return CGSizeMake(0.0f, height);
        }
        
    } else { //if not respond then single page has frame of view
        if (_scrollDirection == AUScrollHorizontalDirection) {        
            return CGSizeMake(CGRectGetWidth(_scrollView.bounds) * _pageCount, 0.0f);
        } else {
            return CGSizeMake(0.0f, CGRectGetHeight(_scrollView.bounds) * _pageCount);
        }    
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)originForPageAtIndex:(NSUInteger)index {

    // if respond to selector then sum all pages to index
    if ([_delegate respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat originX = 0;
        CGFloat originY = 0;
        
        for (NSUInteger i=0; i<index; i++) {
            CGSize size = [_delegate pageScrollView:self pageSizeAtIndex:i];
            originX += size.width;
            originY += size.height;
        }
        
        if (_scrollDirection == AUScrollHorizontalDirection) {
            return CGPointMake(originX, 0.0f);
        } else {
            return CGPointMake(0.0f, originY);
        }
        
    } else { //if not respond then single page has frame of view
        if (_scrollDirection == AUScrollHorizontalDirection) {
            return CGPointMake(CGRectGetWidth(self.bounds) * index, 0.0f);
        } else {
            return CGPointMake(0.0f, CGRectGetHeight(self.bounds) * index);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)pageSizeAtIndex:(NSUInteger)index {

    // if respond to selector then sum all pages to index
    if ([_delegate respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        return [_delegate pageScrollView:self pageSizeAtIndex:index];
    }
    
    return _scrollView.bounds.size;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // get origin and size of page at index
    CGPoint origin = [self originForPageAtIndex:index];
    CGSize size = [self pageSizeAtIndex:index];
    // create rect
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) sendAppearanceDelegateMethodsIfNeeded {
    
    _currentPageIndex = [self currentPageIndex];
    
    // save ivar used to call pageScrollViewDidChangePage method
    if (!_startChangingPageIndex) {
        _startChangingPageIndex = YES;
        _lastPageIndex = _currentPageIndex;
    }
    
    // calculate first visible page
    UIEdgeInsets appearanceInset = UIEdgeInsetsZero; // UIEdgeInsetsMake(-5.0f, -5.0f, 5.0f, 5.0f);
    NSInteger firstVisiblePageIndex = [self firstVisiblePageIndexWithInset:appearanceInset];
    
    if ([self pageExistAtIndex:firstVisiblePageIndex]) {
        if (_indexOfFirstVisiblePage > firstVisiblePageIndex) {
            [self pageDidAppearAtIndex: firstVisiblePageIndex];
            _indexOfFirstVisiblePage = firstVisiblePageIndex;
        }
        else if (_indexOfFirstVisiblePage < firstVisiblePageIndex) {
            [self pageDidDisappearAtIndex: _indexOfFirstVisiblePage];
            _indexOfFirstVisiblePage = firstVisiblePageIndex;
        }
    }    
    
    // calculate last visible page
    NSInteger lastVisiblePageIndex = [self lastVisiblePageIndexWithInset:appearanceInset];
    
    if ([self pageExistAtIndex:lastVisiblePageIndex]) {
        if (_indexOfLastVisiblePage < lastVisiblePageIndex) {
            [self pageDidAppearAtIndex: lastVisiblePageIndex];
            _indexOfLastVisiblePage = lastVisiblePageIndex;
        }
        else if (_indexOfLastVisiblePage > lastVisiblePageIndex) {
            [self pageDidDisappearAtIndex: _indexOfLastVisiblePage];
            _indexOfLastVisiblePage = lastVisiblePageIndex;
        }
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUPageScrollView (Delegates)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageScrollViewStartReloadingData {    
    if ([_delegate respondsToSelector:@selector(pageScrollViewStartReloadingData:)]) {
        [_delegate pageScrollViewStartReloadingData:self];
    }

    // clean flags
    [self cleanFlags];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageScrollViewFinishReloadingData {
    if ([_delegate respondsToSelector:@selector(pageScrollViewFinishReloadingData:)]) {
        [_delegate pageScrollViewFinishReloadingData:self];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageScrollViewDidChangePage:(NSUInteger)previousIndex {

    [[NSNotificationCenter defaultCenter] postNotificationName:AUPageScrollViewDidChangePageNotification 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.tag] 
                                                                                           forKey:AUPageScrollViewTagKey]];
    
    if ([_delegate respondsToSelector:@selector(pageScrollViewDidChangePage:previousPageIndex:)]) {
        [_delegate pageScrollViewDidChangePage:self previousPageIndex:previousIndex];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageDidAppearAtIndex:(NSUInteger)index {
    if (![self pageExistAtIndex:index]) return;

    // bring page to from
    UIView* page = [self pageAtIndex:index];
    [page bringSubviewToFront:page];

//    dispatch_async(dispatch_get_main_queue(), ^ {
        if ([_delegate respondsToSelector:@selector(pageScrollView:pageDidAppearAtIndex:)]) {
            [_delegate pageScrollView:self pageDidAppearAtIndex:index];
        }
//    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageDidDisappearAtIndex:(NSUInteger)index {

    if (![self pageExistAtIndex:index]) return;
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_delegate respondsToSelector:@selector(pageScrollView:pageDidDisappearAtIndex:)]) {
            [_delegate pageScrollView:self pageDidDisappearAtIndex:index];
        }
//    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) willLoadPage:(UIView*)page atIndex:(NSUInteger)index {

    if ([_delegate respondsToSelector:@selector(pageScrollView:willLoadPage:atIndex:)]) {
        [_delegate pageScrollView:self willLoadPage:page atIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) willUnloadPage:(UIView*)page atIndex:(NSUInteger)index {

    if ([_delegate respondsToSelector:@selector(pageScrollView:willUnloadPage:atIndex:)]) {
        [_delegate pageScrollView:self willUnloadPage:page atIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didLoadPage:(UIView*)page atIndex:(NSUInteger)index {

    if ([_delegate respondsToSelector:@selector(pageScrollView:didLoadPage:atIndex:)]) {
        [_delegate pageScrollView:self didLoadPage:page atIndex:index];
    }

    UIView* selectionResponsibleView = page;
    
    // if respond to selector return view from dataSource, else return loaded page
    if ([_dataSource respondsToSelector:@selector(selectionResponsibleViewInPageScrollView:forPageView:)]) {
        selectionResponsibleView = [[self dataSource] selectionResponsibleViewInPageScrollView:self forPageView:page];
    }
    
    // set tag, used in tapGestureRecognizer
    [selectionResponsibleView setTag:index];

    // create tap gesture recognizer 
    UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                                    initWithTarget:self 
                                                    action:@selector(tapGestureAction:)];
//    tapGestureRecognizer.cancelsTouchesInView = NO;
    tapGestureRecognizer.delegate = self;
    
    // add tap gesture recognizer to selectionResponsibleView
    [selectionResponsibleView addGestureRecognizer:tapGestureRecognizer];

    if ([page respondsToSelector:@selector(setSelected:)]) {
        [(AUPageView*)page setSelected:((index == _selectedPageIndex) && (_selectedPageIndex > -1))];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didUnloadPage:(UIView*)page atIndex:(NSUInteger)index {

    if ([_delegate respondsToSelector:@selector(pageScrollView:didUnloadPage:atIndex:)]) {
        [_delegate pageScrollView:self didUnloadPage:page atIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didSelectPageAtIndex:(NSUInteger)index {
    [self didDeselectPageAtIndex:_selectedPageIndex];
    
    if ([_delegate respondsToSelector:@selector(pageScrollView:didSelectPageAtIndex:)]) {
        [[self delegate] pageScrollView:self didSelectPageAtIndex:index];
    }
    
    id page = [self pageAtIndex:index];
    if ([page respondsToSelector:@selector(setSelected:animated:)]) {
        [page setSelected:YES animated:NO];
    }
    
    _selectedPageIndex = index;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didDeselectPageAtIndex:(NSUInteger)index {
    id page = [self pageAtIndex:index];
    if ([page respondsToSelector:@selector(setSelected:animated:)]) {
        [page setSelected:NO animated:NO];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) willBeginDragging {
    if ([_delegate respondsToSelector:@selector(pageScrollViewWillBeginDragging:)]) {
        [_delegate pageScrollViewWillBeginDragging:self];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didEndDragging {
    if ([_delegate respondsToSelector:@selector(pageScrollViewDidEndDragging:)]) {
        [_delegate pageScrollViewDidEndDragging:self];
    }
}

#pragma mark -
#pragma mark UIGestureRecognizer Delegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}

@end

@implementation AUPageScrollView (Private)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)loadPageAtIndex:(NSInteger)index forceLoad:(BOOL)forceLoad {
    // check if index exist
    if (![self pageExistAtIndex: index]) return nil;
    
    id item = [_pages objectAtIndex:index];
    
    // if item at index is null
    if ((item == [NSNull null]) || forceLoad) {
        
        // get page from dataSource
        UIView* view = [_dataSource pageScrollView:self pageAtIndex:index];
        NSAssert(view, @"Assert: Method pageScrollView:pageAtIndex: can't be nil.");
        
        // if got view from dataSorce
        if (view != nil) {
            [UIView setAnimationsEnabled:NO];
            
            //preventive, set frame
            CGRect pageFrame = [self frameForPageAtIndex:index];
            [view setFrame: pageFrame];
            
            // replace in array of pages
            [_pages replaceObjectAtIndex:index withObject:view];
            
            // send delegate
            [self willLoadPage:view atIndex:index];
            
            // add subview
            [_scrollView insertSubview:view atIndex:2];
            
            // send delegate
            [self didLoadPage:view atIndex:index];
            
            // call appearance methods if needed
            [self sendAppearanceDelegateMethodsIfNeeded];
            
            [UIView setAnimationsEnabled:YES];    
            
            // return loaded page
            return view;
        }
    }
    // return page from array
    return item;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) tapGestureAction:(UITapGestureRecognizer*)gestureRecognizer {
    NSUInteger index = [gestureRecognizer.view tag];
    [self didSelectPageAtIndex:index];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cleanFlags {
    _currentPageIndex = _indexOfFirstVisiblePage = _indexOfLastVisiblePage = -1;
    _indexOfFirstLoadedPage = _indexOfLastLoadedPage = -1;

    _startChangingPageIndex = NO;
    _lastPageIndex = -1;
}

@end
