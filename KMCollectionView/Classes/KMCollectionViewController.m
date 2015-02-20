#import "KMCollectionViewController.h"
#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewFlowLayout.h"
#import <BlocksKit/BlocksKit+UIKit.h>


static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+(id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

-(void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

static void * const KMCollectionViewKVOContext = @"KMDataSourceContext";


@interface KMCollectionViewController () <KMCollectionViewDataSourceDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) BOOL wantsContentOffsetUpdates;
@property (nonatomic) BOOL shouldUpdateContentOffset;
@property (nonatomic, copy) void(^pendingContentOffsetUpdateBlocks)();
@property (nonatomic) UIGestureRecognizer *tapToExitGesture;
@end

@implementation KMCollectionViewController

- (instancetype)init
{
    UICollectionViewFlowLayout *flowLayout = [[KMCollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:flowLayout];
    if (self) {
        self.shouldUpdateContentOffset = YES;
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.shouldUpdateContentOffset = YES;
    }
    return self;
}

- (void)dealloc
{
    [self.collectionView removeObserver:self forKeyPath:@"dataSource" context:KMCollectionViewKVOContext];
}

- (void)loadView
{
    [super loadView];
    self.collectionView.pagingEnabled = NO;
    [self.collectionView addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:KMCollectionViewKVOContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    KMCollectionViewDataSource *dataSource = (KMCollectionViewDataSource *)self.collectionView.dataSource;
    if ([dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
        [dataSource registerReusableViewsWithCollectionView:self.collectionView];
        [dataSource setNeedsLoadContent];
    }
    [self addObservers];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeAllObservers];
    [self removeTapGesture];
}


- (void)setCollectionView:(UICollectionView *)collectionView
{
    UICollectionView *oldCollectionView = self.collectionView;
    
    // Always call super, because we don't know EXACTLY what UICollectionViewController does in -setCollectionView:.
    [super setCollectionView:collectionView];
    
    [oldCollectionView removeObserver:self forKeyPath:@"dataSource" context:KMCollectionViewKVOContext];
    
    //  We need to know when the data source changes on the collection view so we can become the delegate for any APPLDataSource subclasses.
    [collectionView addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:KMCollectionViewKVOContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //  For change contexts that aren't the data source, pass them to super.
    if (KMCollectionViewKVOContext != context) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"dataSource"]) {
        UICollectionView *collectionView = object;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        if ([dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
            KMCollectionViewDataSource *kmDataSource = (KMCollectionViewDataSource *)dataSource;
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
    UIGestureRecognizer *tapGesture = [UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [self adjustContentOffsetToApproprate];
    }];
    tapGesture.delegate = self;
    [self.collectionView addGestureRecognizer:tapGesture];
    self.tapToExitGesture = tapGesture;
}

- (void)removeTapGesture
{
    if (self.tapToExitGesture != nil) {
        [self.collectionView removeGestureRecognizer:self.tapToExitGesture];
        self.tapToExitGesture = nil;
    }
}

#pragma mark - Accessors

- (NSString *)cancelationIdentifier
{
    if (_cancelationIdentifier == nil) {
        _cancelationIdentifier = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    }
    return _cancelationIdentifier;
}

#pragma mark Private Methods

- (void)adjustContentOffsetToApproprate
{
    if (self.collectionView.contentSize.height <= self.collectionView.frame.size.height) {
        [UIView animateWithDuration:0.25f animations:^{
            [self.collectionView setContentOffset:CGPointZero animated:YES];
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
    [self performSelector:@selector(addObservers) withObject:nil afterDelay:0.2f];
    [self.collectionViewLayout invalidateLayout];
}

- (void)addObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustCollectionViewContentForKeyboardNotif:) name:UIKeyboardWillHideNotification object:nil];
    [self.collectionView bk_addObserverForKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew task:^(id obj, NSDictionary *change) {
        [self contentOffsetChanged];
    }];
    
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
    [self.collectionView bk_removeAllBlockObservers];
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
    while (currentView != nil && currentView != self.collectionView) {
        if ([currentView isKindOfClass:[UICollectionViewCell class]]) {
            idx = [self.collectionView indexPathForCell:(UICollectionViewCell *)currentView];
            break;
        } else if ([currentView isKindOfClass:[UICollectionReusableView class]]) {
            break;
        }
        currentView = currentView.superview;
    }
    CGFloat animationDuration = [notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect kbdFrame = [notif.userInfo[keyboardKey] CGRectValue];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.collectionView scrollToItemAtIndexPath:idx atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        CGFloat yValue;
        if (self.collectionView.contentSize.height < self.collectionView.contentOffset.y + self.collectionView.frame.size.height && direction == 1){ //Check if we have already scrolled beyond content size of scrollview
            CGFloat oldKeyboardSize = (self.collectionView.contentOffset.y + self.collectionView.frame.size.height) - self.collectionView.contentSize.height;
            
            CGFloat offsetDelta = kbdFrame.size.height - oldKeyboardSize;
            yValue = self.collectionView.contentOffset.y + offsetDelta;
        } else if (self.collectionView.contentOffset.y >= self.collectionView.frame.size.height) {
            yValue = self.collectionView.contentOffset.y + (kbdFrame.size.height * direction);
        } else {
            yValue = (CGRectGetMaxY(currentView.frame) - kbdFrame.origin.y + self.view.frame.origin.y)*direction;
        //avoid pushing views down
        }
        if (yValue < 0.0) {
            return;
        // avoid scrolling back on dismiss the keyboard the collection views content is smaller than the view
        } else if (notif.name == UIKeyboardWillHideNotification && self.collectionView.contentSize.height < self.collectionView.frame.size.height) {
            yValue = 0.0;
        }

        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, yValue) animated:NO];
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
    [self.collectionView performBatchUpdates:^{
        update();
    } completion:^(BOOL finished){
        if (complete) {
            complete();
        }
        [self.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }];
}

- (void)dataSourceWantsToIncreaseVerticalContentOffset:(CGFloat)delta
{
    BOOL wantsUpdateValue = self.wantsContentOffsetUpdates;
    self.wantsContentOffsetUpdates = NO;
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.y += delta;
    self.collectionView.contentOffset = contentOffset;
    self.wantsContentOffsetUpdates = wantsUpdateValue;
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position
{
    
    dispatch_block_t update = ^{
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:position animated:YES];
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
    UICollectionReusableView *cell = [dataSource collectionView:self.collectionView viewForSupplementaryElementOfKind:type atIndexPath:indexPath];
    NSIndexPath *closestIndexPath = nil;
    CGFloat verticalOffset = 0;
    if ([type isEqualToString:UICollectionElementKindSectionFooter]) {
        NSInteger numberOfItemsInSection = [dataSource collectionView:self.collectionView numberOfItemsInSection:section];
        closestIndexPath = [NSIndexPath indexPathForRow:numberOfItemsInSection - 1 inSection:section];
        verticalOffset = cell.frame.size.height;
    } else if ([type isEqualToString:UICollectionElementKindSectionHeader]) {
        closestIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        verticalOffset = cell.frame.size.height * -1;
    }
    void(^update)() = ^{
        self.wantsContentOffsetUpdates = NO;
        [UIView animateWithDuration:0.2 animations:^{
            [self.collectionView scrollToItemAtIndexPath:closestIndexPath atScrollPosition:position animated:NO];
            CGPoint adjustedContentOffset = self.collectionView.contentOffset;
            adjustedContentOffset.y += verticalOffset;
            [self.collectionView setContentOffset:adjustedContentOffset animated:NO];
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
            CGPoint adjustedContentOffset = self.collectionView.contentOffset;
            adjustedContentOffset.y += verticalOffset;
            CGPoint newOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.frame.size.height);
            [self.collectionView setContentOffset:newOffset animated:NO];
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
    [dataSource registerReusableViewsWithCollectionView:self.collectionView];
    [self.collectionView reloadData];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didReloadSections:(NSIndexSet *)sections
{
    [self.collectionView reloadSections:sections];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [self.collectionView performBatchUpdates:^{
        [dataSource registerReusableViewsWithCollectionView:self.collectionView];
        [self.collectionView insertSections:indexSet];
    } completion:^(BOOL finished) {
        [self.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }];
    
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveSectionAtIndexSet:(NSIndexSet *)indexSet
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteSections:indexSet];
    } completion:^(BOOL finished) {
        [self.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }];
}

@end
