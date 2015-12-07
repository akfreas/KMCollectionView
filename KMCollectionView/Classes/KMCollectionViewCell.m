#import "KMCollectionViewCell.h"
#import "KMCellAction.h"
#import "KMCellActionView.h"
#import <PureLayout/PureLayout.h>
NSString *const KMCollectionViewCellNeedsOverrideExceptionName = @"KMNeedsOverrideException";

@interface KMCollectionViewCell ()
@property (nonatomic) UIView *privateContentView;
@property (nonatomic) NSLayoutConstraint *contentLeftConstraint;
@property (nonatomic) KMCellActionView *actionView;
@property (nonatomic) NSArray<KMCellAction *>* cellActions;
@end

@implementation UIView (Helpers)

- (BOOL)aapl_sendAction:(SEL)action
{
    // Get the target in the responder chain
    id sender = self;
    id target = sender;
    
    while (target && ![target canPerformAction:action withSender:sender]) {
        target = [target nextResponder];
    }
    
    if (!target)
        return NO;
    
    return [[UIApplication sharedApplication] sendAction:action to:target from:sender forEvent:nil];
}

@end


@implementation KMCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *contentView = [super contentView];
        _privateContentView = [[UIView alloc] initWithFrame:contentView.bounds];
        [contentView addSubview:_privateContentView];

        _privateContentView.translatesAutoresizingMaskIntoConstraints = NO;

        NSMutableArray *constraints = [NSMutableArray array];

        [constraints addObject:[NSLayoutConstraint
                                constraintWithItem:_privateContentView
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:contentView
                                attribute:NSLayoutAttributeTop
                                multiplier:1
                                constant:0]];
        
        NSLayoutConstraint *_contentHeightConstraint = [NSLayoutConstraint
                                                        constraintWithItem:_privateContentView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                        toItem:contentView
                                                        attribute:NSLayoutAttributeHeight
                                                        multiplier:1
                                                        constant:0];
        [constraints addObject:_contentHeightConstraint];
        
        NSLayoutConstraint *_contentWidthConstraint = [NSLayoutConstraint
                                                       constraintWithItem:_privateContentView
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:contentView
                                                       attribute:NSLayoutAttributeWidth
                                                       multiplier:1
                                                       constant:0];
        [constraints addObject:_contentWidthConstraint];

        _contentLeftConstraint = [NSLayoutConstraint
                                  constraintWithItem:_privateContentView
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:contentView
                                  attribute:NSLayoutAttributeLeft
                                  multiplier:1
                                  constant:0];
        [constraints addObject:_contentLeftConstraint];

        self.layoutMargins = UIEdgeInsetsMake(8, 15, 8, 15);

        [contentView addConstraints:constraints];
        
        _actionView = [[KMCellActionView alloc] initWithCell:self];
        [contentView addSubview:_actionView];

        contentView.clipsToBounds = YES;
    }
    return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    self.hidden = layoutAttributes.hidden;

}


- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins
{
    self.contentView.layoutMargins = layoutMargins;
    [super setLayoutMargins:layoutMargins];
}

- (void)accessoryButtonTapped:(UIButton *)button
{
    KMCellAction *action = [self actionForButton:button];
    [self performAction:action];
    [self closeActionPane];
}

- (void)performAction:(KMCellAction *)action
{
    [self aapl_sendAction:action.action];
}

- (KMCellAction *)actionForButton:(UIButton *)button
{
    KMCellAction *action = _cellActions[button.tag];
    return action;
}

- (void)setCellActions:(NSArray *)actions
{
    _cellActions = [actions copy];
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
    UIView *refView = [super contentView];
    CGRect frame = refView.frame;
    
    [self layoutSubviews];
    
    CGSize fittingSize = CGSizeMake(frame.size.width, UILayoutFittingCompressedSize.height);
    frame.size = [self systemLayoutSizeFittingSize:fittingSize withHorizontalFittingPriority:UILayoutPriorityDefaultHigh verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    
//    refView.frame = originalFrame;
    return frame.size;
}
@end
