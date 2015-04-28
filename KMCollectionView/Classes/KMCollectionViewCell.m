#import "KMCollectionViewCell.h"

@implementation KMCollectionViewCell

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
    NSAssert(NO, @"overrride this method");
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
    return computedSize;
}
@end
