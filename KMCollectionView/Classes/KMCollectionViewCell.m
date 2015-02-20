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
@end
