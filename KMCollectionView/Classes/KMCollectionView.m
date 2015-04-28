#import "KMCollectionView.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewDataManager.h"

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

@interface KMCollectionView () <KMCollectionViewDataSourceDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) BOOL wantsContentOffsetUpdates;
@property (nonatomic) BOOL shouldUpdateContentOffset;
@property (nonatomic) KMCollectionViewDataManager *defaultDataManager;
@property (nonatomic, copy) void(^pendingContentOffsetUpdateBlocks)();
@property (nonatomic) UIGestureRecognizer *tapToExitGesture;
@property (nonatomic) void *KMCollectionViewKVOContext;
@end


@implementation KMCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.KMCollectionViewKVOContext = (__bridge void *)([[NSUUID UUID] UUIDString]);
        self.shouldUpdateContentOffset = YES;
        self.defaultDataManager = [KMCollectionViewDataManager new];
        self.pagingEnabled = NO;
        self.delegate = self.defaultDataManager;
        [self addTransientObservers];
        [self addLifetimeObservers];
    }
    return self;
}

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
        }
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        [self contentOffsetChanged];
    }
}

- (void)addTapGesture
{
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

#pragma mark Private Methods

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillHideNotification object:nil];

    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:self.KMCollectionViewKVOContext];
    
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
    [self removeObserver:self forKeyPath:@"contentOffset"];
    [self removeNotificationObservers];
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
        [self scrollToItemAtIndexPath:idx atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        CGFloat yValue;
        if (self.contentSize.height < self.contentOffset.y + self.frame.size.height && direction == 1){ //Check if we have already scrolled beyond content size of scrollview
            CGFloat oldKeyboardSize = (self.contentOffset.y + self.frame.size.height) - self.contentSize.height;
            
            CGFloat offsetDelta = kbdFrame.size.height - oldKeyboardSize;
            yValue = self.contentOffset.y + offsetDelta;
        } else if (self.contentOffset.y >= self.frame.size.height) {
            yValue = self.contentOffset.y + (kbdFrame.size.height * direction);
        } else {
            CGPoint p = [self convertPoint:kbdFrame.origin fromView:[UIApplication sharedApplication].keyWindow];
            p.y -= CGRectGetHeight(currentView.frame);
            yValue = p.y - self.contentOffset.y;// (CGRectGetMaxY(currentView.frame) - kbdFrame.origin.y + self.frame.origin.y)*direction;
            //avoid pushing views down
        }
        if (yValue < 0.0) { 
            return;
            // avoid scrolling back on dismiss the keyboard the collection views content is smaller than the view
        } else if (notif.name == UIKeyboardWillHideNotification && self.contentSize.height < self.frame.size.height) {
            yValue = 0.0;
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
        [self reloadData];
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

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position
{
    
    dispatch_block_t update = ^{
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:position animated:YES];
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

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryView:(UICollectionReusableView *)cell scrollPosition:(UICollectionViewScrollDirection)position completion:(void (^)())completion
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
    [self reloadSections:sections];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self insertItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self reloadItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self deleteItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self moveItemAtIndexPath:fromIndexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [self performBatchUpdates:^{
        [dataSource registerReusableViewsWithCollectionView:self];
        [self insertSections:indexSet];
    } completion:^(BOOL finished) {
        [self.collectionViewLayout invalidateLayout];
        [self reloadData];
    }];
    
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [self performBatchUpdates:^{
        [self deleteSections:indexSet];
    } completion:^(BOOL finished) {
        [self.collectionViewLayout invalidateLayout];
        [self reloadData];
    }];
}
@end