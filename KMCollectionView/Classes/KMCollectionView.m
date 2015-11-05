#import "KMCollectionView.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewDataManager.h"
#import "KMCollectionViewCell.h"


static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+ (id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@interface KMCollectionView () <KMCollectionViewDataSourceDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UIScrollViewDelegate>
@property (nonatomic) BOOL wantsContentOffsetUpdates;
@property (nonatomic) BOOL shouldUpdateContentOffset;
@property (nonatomic) KMCollectionViewDataManager *defaultDataManager;
@property (nonatomic, copy) void(^pendingContentOffsetUpdateBlocks)();
@property (nonatomic, copy) void(^pendingScrollViewStateCompletionBlocks)();
@property (nonatomic) UIGestureRecognizer *tapToExitGesture;
@property (nonatomic) UISwipeGestureRecognizer *swipeGesture;
@property (nonatomic) void *KMCollectionViewKVOContext;
@property (nonatomic, weak) id<UICollectionViewDelegate> forwardingDelegate;
@property (nonatomic) NSMutableDictionary *contentOffsetObservers;
@end


@interface KMCollectionView (GestureRecognizer)

- (void)handleSwipeGesture:(UIGestureRecognizer *)gesture;

@end

@implementation KMCollectionView (GestureRecognizer)

- (void)handleSwipeGesture:(UIGestureRecognizer *)gesture
{
    
    CGPoint position = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:position];
    KMCollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateEnded:
            [cell openActionPane];
            break;
            
        case UIGestureRecognizerStateChanged:
            
            break;
        default:
            break;
    }
}

@end

@implementation KMCollectionView

#pragma mark Public Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.reactToKeyboard = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.KMCollectionViewKVOContext = (__bridge void *)([[NSUUID UUID] UUIDString]);
        self.shouldUpdateContentOffset = YES;
        self.defaultDataManager = [KMCollectionViewDataManager new];
        self.pagingEnabled = NO;
        _swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        _swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:_swipeGesture];
        self.forwardingDelegate = self.defaultDataManager;
        self.reactToKeyboard = YES;
        self.delegate = self;
        [self addLifetimeObservers];
    }
    return self;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    for (void(^block)(CGPoint) in [self.contentOffsetObservers allValues]) {
        block(*targetContentOffset);
    }
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (delegate == self) {
        [super setDelegate:delegate];
    } else {
        self.forwardingDelegate = delegate;
    }
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated completion:(void(^)())completion
{
    [self enqueueScrollViewActionCompletionBlock:completion];
    [self setContentOffset:contentOffset animated:animated];
}

#pragma mark - Private Methods

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"dataSource" context:self.KMCollectionViewKVOContext];
}

- (void)didMoveToWindow
{
    KMCollectionViewDataSource *dataSource = (KMCollectionViewDataSource *)self.dataSource;
    if ([dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
        [dataSource registerReusableViewsWithCollectionView:self];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow == nil) {
        [self removeAllObservers];
        [self removeTapGesture];
    } else {
        [self addTransientObservers];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //  For change contexts that aren't the data source, pass them to super.
    if (self.KMCollectionViewKVOContext != context) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"dataSource"]) {
        UICollectionView *collectionView = object;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        if ([dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
            KMCollectionViewDataSource *kmDataSource = (KMCollectionViewDataSource *)dataSource;
            [kmDataSource registerReusableViewsWithCollectionView:self];
            if (!kmDataSource.delegate)
                kmDataSource.delegate = self;
            if (kmDataSource.dataManager)
                self.delegate = kmDataSource.dataManager;
        }
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        [self contentOffsetChanged];
    }
}

- (void)addTapGesture
{
    if (self.reactToKeyboard == NO) {
        return;
    }
    if (self.tapToExitGesture != nil) {
        return;
    }
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adjustContentOffsetToAppropriate)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    self.tapToExitGesture = tapGesture;
}

- (void)removeTapGesture
{
    if (self.tapToExitGesture != nil) {
        [self removeGestureRecognizer:self.tapToExitGesture];
        self.tapToExitGesture = nil;
    }
}

- (void)addContentOffsetObserver:(void (^)(CGPoint))observer forKey:(NSString *)key
{
    self.contentOffsetObservers[key] = observer;
}

- (void)removeContentOffsetObserverForKey:(NSString *)key
{
    [self.contentOffsetObservers removeObjectForKey:key];
}

- (NSMutableDictionary *)contentOffsetObservers
{
    if (_contentOffsetObservers == nil) {
        _contentOffsetObservers = [NSMutableDictionary new];
    }
    return _contentOffsetObservers;
}


#pragma mark Forwarding Methods

/*
 For certain purposes, i.e. for knowing when the scroll view has finished decelerating,
 we need to respond to the scroll view delegate methods.  Otherwise, we need to forward
 methods to the delegate that was set outside the collection view.  If the delegate set 
 outside conforms to UIScrollViewDelegate, then naturally the dataSource:wantsToScrollToItemAtIndexPath:scrollPosition:completion:
 won't work as usual.

 */

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([KMCollectionView instancesRespondToSelector:aSelector] == NO && [self.forwardingDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return [KMCollectionView instancesRespondToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.forwardingDelegate;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.pendingScrollViewStateCompletionBlocks) {
        self.pendingScrollViewStateCompletionBlocks();
        self.pendingScrollViewStateCompletionBlocks = nil;
    }
}

- (void)adjustContentOffsetToAppropriate
{
    if (self.contentSize.height <= self.frame.size.height) {
        [UIView animateWithDuration:0.25f animations:^{
            [self setContentOffset:CGPointZero animated:YES];
        }];
    }
}

- (void)contentOffsetChanged
{
    /* If we are setting the content offset manually, we want to disable
     the action of content offset updates. This should only get triggered
     when the user touches the scroll view and scrolls or some other content
     offset change is made that we didn't trigger.
     */
    if (self.wantsContentOffsetUpdates == NO) {
        return;
    }
    [self removeAllObservers];
    UIResponder *currentResponder = [UIResponder currentFirstResponder];
    [currentResponder resignFirstResponder];
    [self removeTapGesture];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addTransientObservers) object:nil];
    [self performSelector:@selector(addTransientObservers) withObject:nil afterDelay:0.2f];
    [self.collectionViewLayout invalidateLayout];
}

- (void)addLifetimeObservers
{
    [self addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:self.KMCollectionViewKVOContext];
}

- (void)addTransientObservers
{
    if (self.reactToKeyboard == NO) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeKeyboardAnimationState:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeKeyboardAnimationState:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeKeyboardAnimationState:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeKeyboardAnimationState:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)changeKeyboardAnimationState:(NSNotification *)notif
{
    NSString *notifName = notif.name;
    BOOL keyboardIsAnimating = NO;
    if (notifName == UIKeyboardWillShowNotification || notifName == UIKeyboardWillHideNotification) {
        keyboardIsAnimating = YES;
    } else if (notifName == UIKeyboardDidHideNotification || notifName == UIKeyboardDidShowNotification) {
        keyboardIsAnimating = NO;
    }
    
    if (keyboardIsAnimating == NO) {
        if (self.pendingContentOffsetUpdateBlocks) {
            self.pendingContentOffsetUpdateBlocks();
            self.pendingContentOffsetUpdateBlocks = nil;
        }
    }
    self.shouldUpdateContentOffset = keyboardIsAnimating == NO;
}

- (void)removeAllObservers
{
    [self removeNotificationObservers];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self contentOffsetChanged];
}

- (void)removeNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)adjustCollectionViewContentForKeyboardNotif:(NSNotification *)notif
{
    NSInteger direction = 0;
    NSString *keyboardKey;
    self.wantsContentOffsetUpdates = NO;
    if (notif.name == UIKeyboardWillHideNotification) {
        direction = -1;
        keyboardKey = UIKeyboardFrameBeginUserInfoKey;
        [self removeTapGesture];
    } else if (notif.name == UIKeyboardWillShowNotification) {
        direction = 1;
        keyboardKey = UIKeyboardFrameEndUserInfoKey;
        [self addTapGesture];
    }
    UIResponder *currentResponder = [UIResponder currentFirstResponder];
    if ([currentResponder isKindOfClass:[UIView class]] == NO) {
        return;
    }

    UIView *currentView = (UIView *)currentResponder;
    NSIndexPath *idx;
    while (currentView != nil && currentView != self) {
        if ([currentView isKindOfClass:[UICollectionViewCell class]]) {
            idx = [self indexPathForCell:(UICollectionViewCell *)currentView];
            break;
        } else if ([currentView isKindOfClass:[UICollectionReusableView class]]) {
            break;
        }
        currentView = currentView.superview;
    }
    CGFloat animationDuration = [notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect kbdFrame = [notif.userInfo[keyboardKey] CGRectValue];
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat yValue;
        CGRect converted = [self convertRect:kbdFrame fromView:[[UIApplication sharedApplication] keyWindow]];
        
        if (notif.name == UIKeyboardWillHideNotification && self.contentSize.height < self.frame.size.height) {
            yValue = 0.0;
        } else if (converted.origin.y > CGRectGetMaxY(currentView.frame)) {
            yValue = self.contentOffset.y;
        } else {
            yValue = currentView.frame.origin.y + currentView.frame.size.height + self.contentOffset.y - converted.origin.y;
        }
        [self setContentOffset:CGPointMake(self.contentOffset.x, yValue) animated:NO];
        
    } completion:^(BOOL finished) {
        if (notif.name == UIKeyboardWillHideNotification) {
            self.wantsContentOffsetUpdates = NO;
            [self removeTapGesture];
        } else if (notif.name == UIKeyboardWillShowNotification) {
            self.wantsContentOffsetUpdates = YES;
        }
    }];
    
}

- (void)enqueueContentOffsetUpdateBlock:(dispatch_block_t)block
{
    dispatch_block_t previousBlock = self.pendingContentOffsetUpdateBlocks;
    if (previousBlock) {
        self.pendingContentOffsetUpdateBlocks = ^{
            previousBlock();
            block();
        };
    } else {
        self.pendingContentOffsetUpdateBlocks = block;
    }
}

- (void)enqueueScrollViewActionCompletionBlock:(dispatch_block_t)block
{
    dispatch_block_t previousBlock = self.pendingScrollViewStateCompletionBlocks;
    if (previousBlock) {
        self.pendingScrollViewStateCompletionBlocks = ^{
            previousBlock();
            block();
        };
    } else {
        self.pendingScrollViewStateCompletionBlocks = block;
    }
}

#pragma mark KMCollectionViewDataSourceDelegate

- (void)dataSource:(KMCollectionViewDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    [self performBatchUpdates:^{
        update();
    } completion:^(BOOL finished){
        if (complete) {
            complete();
        }
        [self.collectionViewLayout invalidateLayout];
    }];
}

- (void)dataSourceWantsToIncreaseVerticalContentOffset:(CGFloat)delta
{
    BOOL wantsUpdateValue = self.wantsContentOffsetUpdates;
    self.wantsContentOffsetUpdates = NO;
    CGPoint contentOffset = self.contentOffset;
    contentOffset.y += delta;
    self.contentOffset = contentOffset;
    self.wantsContentOffsetUpdates = wantsUpdateValue;
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated
{
    
    dispatch_block_t update = ^{
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:position animated:animated];
    };
    
    if (self.shouldUpdateContentOffset) {
        update();
    } else {
        [self enqueueContentOffsetUpdateBlock:update];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated completion:(void(^)(UICollectionViewCell *))completion
{
    __weak typeof(&*self) weakSelf = self;
    dispatch_block_t update = ^{
        @try {
            [weakSelf scrollToItemAtIndexPath:indexPath atScrollPosition:position animated:animated];
        }
        @catch (NSException *exception) {
            if (completion) {
                completion(nil);
            }
        }
        if (completion) {
            if (animated == NO) {
                UICollectionViewCell *cell = [weakSelf cellForItemAtIndexPath:indexPath];
                completion(cell);
            } else {
                [weakSelf enqueueScrollViewActionCompletionBlock:^{
                    UICollectionViewCell *cell = [weakSelf cellForItemAtIndexPath:indexPath];
                        completion(cell);
                }];
            }
        }
    };
    
    if (self.shouldUpdateContentOffset) {
        update();
    } else {
        [self enqueueContentOffsetUpdateBlock:update];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position
{
    [self dataSource:dataSource wantsToScrollToSupplementaryViewOfType:type inSection:section scrollPosition:position completion:nil];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)(UICollectionReusableView *))completion
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    UICollectionReusableView *cell = [dataSource collectionView:self viewForSupplementaryElementOfKind:type atIndexPath:indexPath];
    NSIndexPath *closestIndexPath = nil;
    CGFloat verticalOffset = 0;
    if ([type isEqualToString:UICollectionElementKindSectionFooter]) {
        NSInteger numberOfItemsInSection = [dataSource collectionView:self numberOfItemsInSection:section];
        closestIndexPath = [NSIndexPath indexPathForRow:numberOfItemsInSection - 1 inSection:section];
        verticalOffset = cell.frame.size.height;
    } else if ([type isEqualToString:UICollectionElementKindSectionHeader]) {
        closestIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        verticalOffset = cell.frame.size.height * -1;
    }
    void(^update)() = ^{
        self.wantsContentOffsetUpdates = NO;
        [UIView animateWithDuration:0.2 animations:^{
            [self scrollToItemAtIndexPath:closestIndexPath atScrollPosition:position animated:NO];
            CGPoint adjustedContentOffset = self.contentOffset;
            adjustedContentOffset.y += verticalOffset;
            [self setContentOffset:adjustedContentOffset animated:NO];
        } completion:^(BOOL finished) {
            self.wantsContentOffsetUpdates = YES;
            if (completion) {
                completion(cell);
            }
        }];
    };
    if (self.shouldUpdateContentOffset) {
        update();
    } else {
        [self enqueueContentOffsetUpdateBlock:update];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryView:(UICollectionReusableView *)cell scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)())completion
{
    CGFloat verticalOffset = 30.0;
    void(^update)() = ^{
        self.wantsContentOffsetUpdates = NO;
        [UIView animateWithDuration:0.2 animations:^{
            CGPoint adjustedContentOffset = self.contentOffset;
            adjustedContentOffset.y += verticalOffset;
            CGPoint newOffset = CGPointMake(0, self.contentSize.height - self.frame.size.height);
            [self setContentOffset:newOffset animated:NO];
        } completion:^(BOOL finished) {
            self.wantsContentOffsetUpdates = YES;
            if (completion) {
                completion(cell);
            }
        }];
    };
    if (self.shouldUpdateContentOffset) {
        update();
    } else {
        [self enqueueContentOffsetUpdateBlock:update];
    }
    
}

- (void)dataSourceWantsToInvalidateLayout:(KMCollectionViewDataSource *)dataSource
{
    [self.collectionViewLayout invalidateLayout];
}

- (void)dataSourceDidReloadData:(KMCollectionViewDataSource *)dataSource
{
    [dataSource registerReusableViewsWithCollectionView:self];
    [self reloadData];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didReloadSections:(NSIndexSet *)sections
{
    @try {
        [self reloadSections:sections];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    @try {
        [self insertItemsAtIndexPaths:indexPaths];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    @try {
        [self reloadItemsAtIndexPaths:indexPaths];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    @try {
        [self deleteItemsAtIndexPaths:indexPaths];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self moveItemAtIndexPath:fromIndexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [dataSource registerReusableViewsWithCollectionView:self];
    [self insertSections:indexSet];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [self deleteSections:indexSet];
}
@end
