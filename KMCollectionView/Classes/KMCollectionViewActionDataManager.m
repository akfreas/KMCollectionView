#import "KMCollectionViewActionDataManager.h"

@implementation KMCollectionViewActionDataManager

#pragma mark UICollectionViewControllerDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

@end
