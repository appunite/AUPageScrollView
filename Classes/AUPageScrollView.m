//
//  AUPageScrollView.m
//
//  Created by Emil Wojtaszek on 25.11.2011.
//  Copyright (c)2011 AppUnite.com. All rights reserved.
//

#import "AUPageScrollView.h"
#import "AUPageView.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface AUPageScrollView (Private)
- (void)cleanFlags;
- (void)tapGestureAction:(UITapGestureRecognizer*)gestureRecognizer;
- (UIView *)loadPageAtIndex:(NSInteger)index forceLoad:(BOOL)forceLoad;
@end

NSString* AUPageScrollViewDidChangePageNotification = @"AUPageScrollViewDidChangePageNotification";
NSString* AUPageScrollViewTagKey = @"kAUPageScrollViewTagKey";

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUPageScrollView
@synthesize dataSource = _dataSource;
@synthesize scrollDirection = _scrollDirection;
@synthesize pages = _pages;

#pragma mark -
#pragma mark Dealloc

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    _dataSource = nil;
}

#pragma mark -
#pragma mark Inits

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setup {
    // clean flags
    [self cleanFlags];
    
    //create array
    _pages = [[NSMutableArray alloc] init];
        
    _loadInset = UIEdgeInsetsZero;
    _scrollDirection = AUScrollHorizontalDirection;
    _selectedPageIndex = -1;
    _isLoading = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame scrollDirection:(AUScrollDirection)scrollDirection {
    self = [self initWithFrame:frame];
    if (self) {
        _scrollDirection = scrollDirection;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // dont't call if no pages
    if ([_pages count] == 0 || _rotationInProgress) return;
    
    // load boundary pages
    [self layoutPages];
    
    // get load inset
    UIEdgeInsets loadInset = _loadInset;
    
    // calculate range of visible pages
    NSRange range = [self visiblePagesRangeWithInset:loadInset];
    
    if ((_indexOfFirstLoadedPage != range.location) || (_indexOfLastLoadedPage != range.location + range.length -1)) {
        // save flags
        _indexOfFirstLoadedPage = range.location; _indexOfLastLoadedPage = range.location + range.length -1;
    }

    // send pageDidAppear:/pageDidDisappera: notifications
    [self sendAppearanceDelegateMethodsIfNeeded];
    
    // send didChangePage: notification
    if (_currentPageIndex != _lastPageIndex) {
        [self pageScrollViewDidChangePage:_lastPageIndex]; 
        _lastPageIndex = _currentPageIndex;
    }
}

#pragma mark -
#pragma mark Getters & setters

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setScrollDirection:(AUScrollDirection)scrollDirection {
    if (scrollDirection != _scrollDirection) {
        [self setContentOffset:CGPointZero];
        [self setContentSize:CGSizeZero];
        _scrollDirection = scrollDirection;
        [_pages removeAllObjects];
        [self cleanFlags];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id<AUPageScrollViewDelegate>)delegate {
    return (id<AUPageScrollViewDelegate>)[super delegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setDelegate:(id<AUPageScrollViewDelegate>)delegate {
    [super setDelegate:delegate];
}

#pragma mark -
#pragma mark Class methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)reloadData {
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
    [self setContentSize:contentSize];
	
	// Load first visible pages
    UIEdgeInsets inset = _loadInset;
    NSRange range = [self visiblePagesRangeWithInset:inset];
    
    for (NSInteger i=0; i<range.length; i++) {
        [self loadPageAtIndex:i + range.location];
    }
    
    //send delegate method
    [self pageScrollViewFinishReloadingData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)reloadVisiblePages {
	// Load first visible pages
    NSRange range = [self visiblePagesRangeWithInset:UIEdgeInsetsZero];
    
    for (NSInteger i=range.location; i<range.length+range.location; i++) {
        if (![self pageAtIndex:i]) {
            [self loadPageAtIndex:i forceLoad:YES];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)reloadCurrentPage {
//    // get current page index
//    NSInteger index = [self currentPageIndex];
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
- (UIView*)pageAtIndex:(NSInteger)index {
    // return nil if page doesn't exist
    if (![self pageExistAtIndex:index]) return nil;
    // get object from array
    id item = [_pages objectAtIndex:index];
    // return page if is not NSNull
    return (item == [NSNull null])? nil : item;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadBoundaryPages:(BOOL)forced {
    // get load inset
    UIEdgeInsets loadInset = _loadInset;

    // calculate range of visible pages
    NSRange range = [self visiblePagesRangeWithInset:loadInset];

    // load pages in range
    for (NSInteger i=range.location; i<=range.location + range.length - 1; i++) {
        [self loadPageAtIndex:i forceLoad:forced];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadUnnecessaryPages {
    // prepare variables
    UIEdgeInsets inset = _loadInset;

    // calculate range of visible pages
    NSRange range = [self visiblePagesRangeWithInset:inset];

    // create insex set to return
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    
    // find pages to unload
    for (NSInteger index = 0; index < _pageCount; index++) {
        id item = [_pages objectAtIndex:index];
        
        if (item != [NSNull null]) {
            if ((index < range.location) || (index > range.location + range.length -1)) {
                [indexSet addIndex:index];
            }
        }
    }
    
    // unload pages
    [self unloadPageAtIndexes:indexSet];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadAllPagesExcept:(NSInteger)exceptIndex {
    
    // create insex set to return
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    
    // find pages to unload
    for (NSInteger index = 0; index < _pageCount; index++) {
        id item = [_pages objectAtIndex:index];
        
        if ((item != [NSNull null])&& (index != exceptIndex)) {
            [indexSet addIndex:index];
        }
    }
    
    // unload pages
    [self unloadPageAtIndexes:indexSet];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutPages {
    [self loadBoundaryPages:NO];
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

        if (_rotationInProgress && NSLocationInRange(index, _rangeBeforeRotation)) {
            return;
        }
        
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
    // enumarate insex set and unload page at index
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop) {
        [self unloadPageAtIndex:idx];
    }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadInvisiblePages {
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
                NSInteger index = [_pages indexOfObject:item];
                [self unloadPageAtIndex:index];
            }
            
            // set flag to YES
            canUnload = YES;
            
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unloadAllPages {
    
    NSEnumerator* enumerator = [_pages reverseObjectEnumerator];
    // enumerate all pages
    for (id item in enumerator) {
        // check if item is UIView class
        if ([item isKindOfClass:[UIView class]]) {
            // remove view form superview
            [item removeFromSuperview];
            // replace that item with NSNull ibject
            NSInteger index = [_pages indexOfObject:item];
            [_pages replaceObjectAtIndex:index withObject:[NSNull null]];
        }
    }
    
    // remove all pages
	[_pages removeAllObjects];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)scrollToPageIndex:(NSInteger)index animated:(BOOL)animated {
    // get origin of page at index
    CGPoint point = [self originForPageAtIndex:index];
    // set content offset
    [self setContentOffset:point animated:animated];
    
    // reload visible pages
    [self reloadVisiblePages];
    
    // invoke page did appera/disappear
    [self sendAppearanceDelegateMethodsIfNeeded];
    
    // return page at index path
    return [self pageAtIndex:index];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexSet *)indexesOfPages {
    NSArray* objects = [self pages];
    
    if (![objects count]) {
        return ([NSIndexSet indexSet]);
    }
    
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
    
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [indexes addIndex: idx];
    }];
    
    return indexes;
}

#pragma mark -
#pragma mark Handling View Rotations

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // set rotation flag
    _rotationInProgress = YES;    
    _rangeBeforeRotation = [self visiblePagesRangeWithInset:UIEdgeInsetsZero];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationWithDuration:(NSTimeInterval)duration {    

    // set up content size
    CGSize size = [self scrollContentSize];
    [self setContentSize:size];

    // layout loaded subviews
    NSRange range = _rangeBeforeRotation;
    for (NSInteger i=range.location; i<=range.length + range.location - 1; i++) {

        // get page from dataSource
        UIView* view = [self pageAtIndex:i];

        // preventive, set frame
        CGRect pageFrame = [self frameForPageAtIndex:i];
        [view setFrame: pageFrame];
    }

    // set up content offset
    CGRect frame = [self frameForPageAtIndex:range.location];
    self.contentOffset = frame.origin;

}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {    
    // clear rotation flag
    _rotationInProgress = NO;
}

#pragma mark -
#pragma mark UIScrollView Delegate

/////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    if (_startChangingPageIndex) {
//        if (_currentPageIndex != _lastPageIndex) {
//            [self pageScrollViewDidChangePage:_lastPageIndex]; 
//            _startChangingPageIndex = NO;
//        }
//    }    
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    if (_startChangingPageIndex) {
//        if (_currentPageIndex != _lastPageIndex) {
//            [self pageScrollViewDidChangePage:_lastPageIndex]; 
//            _startChangingPageIndex = NO;
//        }
//    }  
//}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AUPageScrollView (Calculation)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)pageExistAtIndex:(NSInteger)index {
    return (([_pages count] > 0)&&
            (index >= 0)&& 
            (index <= [_pages count] - 1));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)currentPageIndex {
    if (_scrollDirection == AUScrollHorizontalDirection) {
        return MIN(MAX(0, floorf((self.contentOffset.x + self.bounds.size.width * 0.5f)/ self.bounds.size.width)), _pageCount);
    } else {
        return MIN(MAX(0, floorf((self.contentOffset.y + self.bounds.size.height * 0.5f)/ self.bounds.size.height)), _pageCount);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)firstVisiblePageIndexWithInset:(UIEdgeInsets)inset {
    CGPoint contentOffset = CGPointMake(ceilf(self.contentOffset.x + inset.left + FLT_EPSILON), 
                                        ceilf(self.contentOffset.y + inset.top + FLT_EPSILON));    
    return [self indexOfPageContainsPoint:contentOffset];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)lastVisiblePageIndexWithInset:(UIEdgeInsets)inset {
    if (_pageCount == 0) return 0;
    
    // calculate farthest point
    CGPoint contentOffset = CGPointZero;
    if (_scrollDirection == AUScrollHorizontalDirection) {
        contentOffset = CGPointMake(floorf(self.contentOffset.x + self.bounds.size.width - inset.right) - 0.1f,
                                    floorf(self.contentOffset.y - inset.bottom));
        
    } else {
        contentOffset = CGPointMake(floorf(self.contentOffset.x - inset.right), 
                                    floorf(self.contentOffset.y + self.bounds.size.height - inset.bottom) - 0.1f);
    }
    
    // get working content size
    CGSize contentSize = [self scrollContentSize];

    // if calculated point is further than calculated point, return last page index
    if ((contentOffset.x + inset.left > MAX(0, contentSize.width - CGRectGetWidth(self.bounds))) || (contentOffset.y + inset.top > MAX(0, contentSize.height - CGRectGetHeight(self.bounds)))) {
        return _pageCount -1;
    }
    
    // find page with point
    return [self indexOfPageContainsPoint:contentOffset];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)indexOfPageContainsPoint:(CGPoint)point {
    
    NSInteger index = 0;
    
    // if respond to selector then sum all pages to index
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat originX = 0;
        CGFloat originY = 0;
        
        CGSize size = CGSizeZero;
        CGRect rect = CGRectZero;
        for (NSInteger i=0; i<_pageCount; i++) {
            
            size = [[self delegate] pageScrollView:self pageSizeAtIndex:i];
            
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
            CGFloat contentOffset = point.x + FLT_EPSILON;
            index = floorf((contentOffset)/ self.bounds.size.width);
        } else {
            CGFloat contentOffset = point.y + FLT_EPSILON;
            index = floorf((contentOffset)/ self.bounds.size.height);
        }
    }
    
    return MAX(0, index);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray*)visiblePages {
    // calculate first visible page and visible page count
    NSRange range = [self visiblePagesRangeWithInset:UIEdgeInsetsZero];
    
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
    // find first and last visible page index
    NSInteger indexOfFirstVisiblePage = [self firstVisiblePageIndexWithInset:inset];
    NSInteger indexOfLastVisiblePage = [self lastVisiblePageIndexWithInset:inset];
    
    return NSMakeRange(MAX(0, indexOfFirstVisiblePage), MAX(0, indexOfLastVisiblePage - indexOfFirstVisiblePage + 1));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)scrollContentSize {
    
    // if respond to selector then sum all pages to index
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat width = 0;
        CGFloat height = 0;
        
        for (NSInteger i=0; i<_pageCount; i++) {
            CGSize size = [[self delegate] pageScrollView:self pageSizeAtIndex:i];
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
            return CGSizeMake(CGRectGetWidth(self.bounds)* _pageCount, 0.0f);
        } else {
            return CGSizeMake(0.0f, CGRectGetHeight(self.bounds)* _pageCount);
        }    
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)originForPageAtIndex:(NSInteger)index {
    
    // if respond to selector then sum all pages to index
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        
        CGFloat originX = 0;
        CGFloat originY = 0;
        
        for (NSInteger i=0; i<index; i++) {
            CGSize size = [[self delegate] pageScrollView:self pageSizeAtIndex:i];
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
            return CGPointMake(CGRectGetWidth(self.bounds)* index, 0.0f);
        } else {
            return CGPointMake(0.0f, CGRectGetHeight(self.bounds)* index);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)pageSizeAtIndex:(NSInteger)index {
    
    // if respond to selector then sum all pages to index
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageSizeAtIndex:)]) {
        return [[self delegate] pageScrollView:self pageSizeAtIndex:index];
    }
    
    return self.bounds.size;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)frameForPageAtIndex:(NSInteger)index {
    // get origin and size of page at index
    CGPoint origin = [self originForPageAtIndex:index];
    CGSize size = [self pageSizeAtIndex:index];
    // create rect
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendAppearanceDelegateMethodsIfNeeded {
    
    _currentPageIndex = [self currentPageIndex];
    
    // save ivar used to call pageScrollViewDidChangePage method
//    if (!_startChangingPageIndex) {
//        _startChangingPageIndex = YES;
//        _lastPageIndex = _currentPageIndex;
//    }
    
    // calculate first visible page
    UIEdgeInsets appearanceInset = UIEdgeInsetsZero; // UIEdgeInsetsMake(-5.0f, -5.0f, 5.0f, 5.0f);
    NSRange range = [self visiblePagesRangeWithInset:appearanceInset];
    
    // take care of left side
    if ([self pageExistAtIndex:range.location]) {
        if (_indexOfFirstVisiblePage > range.location) {
            [self pageDidAppearAtIndex: range.location];
            _indexOfFirstVisiblePage = range.location;
        }
        else if (_indexOfFirstVisiblePage < range.location) {
            [self pageDidDisappearAtIndex: _indexOfFirstVisiblePage];
            _indexOfFirstVisiblePage = range.location;
        }
    }    
    
    // take care of right side
    NSInteger lastVisiblePageIndex = range.location + range.length -1;
    if ([self pageExistAtIndex:lastVisiblePageIndex]) {
//    if ([self pageExistAtIndex:lastVisiblePageIndex] && (lastVisiblePageIndex != range.location || range.location == 0)) {
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
- (void)pageScrollViewStartReloadingData {    
    if ([[self delegate] respondsToSelector:@selector(pageScrollViewStartReloadingData:)]) {
        [[self delegate] pageScrollViewStartReloadingData:self];
    }
    
    // clean flags
    [self cleanFlags];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pageScrollViewFinishReloadingData {
    if ([[self delegate] respondsToSelector:@selector(pageScrollViewFinishReloadingData:)]) {
        [[self delegate] pageScrollViewFinishReloadingData:self];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pageScrollViewDidChangePage:(NSInteger)previousIndex {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AUPageScrollViewDidChangePageNotification 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.tag] 
                                                                                           forKey:AUPageScrollViewTagKey]];
    
    if ([[self delegate] respondsToSelector:@selector(pageScrollViewDidChangePage:previousPageIndex:)]) {
        [[self delegate] pageScrollViewDidChangePage:self previousPageIndex:previousIndex];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pageDidAppearAtIndex:(NSInteger)index {
    if (![self pageExistAtIndex:index]) return;
    
    // bring page to from
    UIView* page = [self pageAtIndex:index];
    [page bringSubviewToFront:page];
    
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageDidAppearAtIndex:)]) {
        [[self delegate] pageScrollView:self pageDidAppearAtIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pageDidDisappearAtIndex:(NSInteger)index {
    
    if (![self pageExistAtIndex:index]) return;
    
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:pageDidDisappearAtIndex:)]) {
        [[self delegate] pageScrollView:self pageDidDisappearAtIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didLoadPage:(UIView*)page atIndex:(NSInteger)index {
        
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
        [(AUPageView*)page setSelected:((index == _selectedPageIndex)&& (_selectedPageIndex > -1))];
    }

    if ([[self delegate] respondsToSelector:@selector(pageScrollView:didLoadPage:atIndex:)]) {
        [[self delegate] pageScrollView:self didLoadPage:page atIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didUnloadPage:(UIView*)page atIndex:(NSInteger)index {
    
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:didUnloadPage:atIndex:)]) {
        [[self delegate] pageScrollView:self didUnloadPage:page atIndex:index];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didSelectPageAtIndex:(NSInteger)index {
    [self didDeselectPageAtIndex:_selectedPageIndex];
    
    if ([[self delegate] respondsToSelector:@selector(pageScrollView:didSelectPageAtIndex:)]) {
        [[self delegate] pageScrollView:self didSelectPageAtIndex:index];
    }
    
    id page = [self pageAtIndex:index];
    if ([page respondsToSelector:@selector(setSelected:animated:)]) {
        [page setSelected:YES animated:NO];
    }
    
    _selectedPageIndex = index;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didDeselectPageAtIndex:(NSInteger)index {
    id page = [self pageAtIndex:index];
    if ([page respondsToSelector:@selector(setSelected:animated:)]) {
        [page setSelected:NO animated:NO];
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
            
            // save flags
            _isLoading = YES;
            
            // preventive, set frame
            CGRect pageFrame = [self frameForPageAtIndex:index];
            [view setFrame: pageFrame];
            
            // replace in array of pages
            [_pages replaceObjectAtIndex:index withObject:view];
            
            // add subview
            [self.intermediateView insertSubview:view atIndex:2];
            
            // send delegate
            [self didLoadPage:view atIndex:index];
            
            // call appearance methods if needed
            [self sendAppearanceDelegateMethodsIfNeeded];
            
            // save flags
            _isLoading = NO;

            [UIView setAnimationsEnabled:YES];    

            // return loaded page
            return view;
        }
    }

    // if view is loaded just ensure it is in proper location
    if (item != [NSNull null]) {
        // get page from dataSource
        UIView* view = (UIView*)item;
        
        // preventive, set frame
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [view setFrame: pageFrame];
    }

    // return page from array
    return item;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tapGestureAction:(UITapGestureRecognizer*)gestureRecognizer {
    NSInteger index = [gestureRecognizer.view tag];
    [self didSelectPageAtIndex:index];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cleanFlags {
    _currentPageIndex = _indexOfFirstVisiblePage = _indexOfLastVisiblePage = -1;
    _indexOfFirstLoadedPage = _indexOfLastLoadedPage = -1;
    
    _startChangingPageIndex = NO;
    _lastPageIndex = -1;
}

@end
