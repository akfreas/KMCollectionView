#import "KMCollectionViewCell.h"
#import "KMCellAction.h"
#import "KMCellActionView.h"
#import <PureLayout/PureLayout.h>
NSString *const KMCollectionViewCellNeedsOverrideExceptionName = @"KMNeedsOverrideException";

@interface KMCollectionViewCell ()
@property (nonatomic) UIView *privateContentView;
@property (nonatomic) NSLayoutConstraint *contentLeftConstraint;
@property (nonatomic) KMCellActionView *actionView;
@end

@implementation KMCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *contentView = [super contentView];
        _privateContentView = [[UIView alloc] initWithFrame:CGRectZero];
        [contentView addSubview:_privateContentView];
        _privateContentView.translatesAutoresizingMaskIntoConstraints = NO;

        NSMutableArray *constraints = [NSMutableArray array];

        [constraints addObject:[NSLayoutConstraint constraintWithItem:_privateContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        
        NSLayoutConstraint *_contentHeightConstraint = [NSLayoutConstraint constraintWithItem:_privateContentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
        [constraints addObject:_contentHeightConstraint];
        
        NSLayoutConstraint *_contentWidthConstraint = [NSLayoutConstraint constraintWithItem:_privateContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
        [constraints addObject:_contentWidthConstraint];
        
        _contentLeftConstraint = [NSLayoutConstraint constraintWithItem:_privateContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        [constraints addObject:_contentLeftConstraint];
        
        [contentView addConstraints:constraints];
        
        _actionView = [[KMCellActionView alloc] init];
        [contentView addSubview:_actionView];

        contentView.clipsToBounds = YES;
    }
    return self;
}

- (void)setCellActions:(NSArray *)actions
{
    [self.actionView addSubviewsForActions:actions];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.contentView layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)_invalidateCollectionViewLayout
{
    UICollectionView *collectionView = (UICollectionView *)self.superview;
    
    while (collectionView && ![collectionView isKindOfClass:[UICollectionView class]])
        collectionView = (UICollectionView *)collectionView.superview;
    
    if (!collectionView)
        return;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
    if (![layout isKindOfClass:[UICollectionViewFlowLayout class]])
        return;
    
    NSIndexPath *indexPath = [collectionView indexPathForCell:self];
    if (!indexPath)
        return;
    
    [layout invalidateLayout];
}

- (void)configureCellDataWithObject:(NSObject *)object
{
    [NSException raise:KMCollectionViewCellNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
}

- (UIView *)contentView
{
    return _privateContentView;
}

- (void)closeActionPane
{
    _contentLeftConstraint.constant = 0.0;
    UIView *contentView = [super contentView];

    [UIView animateWithDuration:0.2 animations:^{
        [contentView layoutSubviews];
    } completion:^(BOOL finished) {
        [self removeConstraintsRelatedToView:_actionView];
        [contentView layoutSubviews];
    }];
    
}

- (void)removeConstraintsRelatedToView:(UIView *)view
{
    for (NSLayoutConstraint *constraint in self.constraints) {
        if (constraint.firstItem == view || constraint.secondItem == view) {
            [self removeConstraint:constraint];
        }
    }
}

- (void)openActionPaneWithActions:(NSArray<KMCellAction *>*)actions
{
    CGFloat drawerSize = 70.0 * [actions count];
    _contentLeftConstraint.constant = -drawerSize;

    UIView *contentView = [super contentView];
    contentView.clipsToBounds = NO;
    [_actionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_privateContentView];
    [_actionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:contentView];
    [_actionView autoSetDimension:ALDimensionWidth toSize:drawerSize];
    [_actionView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:contentView];
    [_actionView layoutIfNeeded];
    [UIView animateWithDuration:0.2 animations:^{
        [contentView layoutIfNeeded];
    }];
}

- (CGSize)prepreferredLayoutSizeFittingSize:(CGSize)targetSize
{
    CGRect originalFrame = self.frame;
    
    // assert: targetSize.width has the required width of the cell
    
    // step1: set the cell.frame to use that width
    CGRect frame = self.frame;
    frame.size = targetSize;
    self.frame = frame;
    
    // step2: layout the cell
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // assert: the label's bounds and preferredMaxLayoutWidth are set to the width required by the cell's width
    
    // step3: compute how tall the cell needs to be
    
    // this causes the cell to compute the height it needs, which it does by asking the
    // label what height it needs to wrap within its current bounds (which we just set).
    CGSize computedSize = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    self.frame = originalFrame;
    return computedSize;
}
@end
