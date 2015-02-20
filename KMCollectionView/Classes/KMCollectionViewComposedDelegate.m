#import "KMCollectionViewComposedDelegate.h"
#import "KMCollectionViewUtilities.h"

@interface KMCollectionViewComposedDelegate ()
@property (nonatomic) NSMutableDictionary *delegateMapping;
@end

@implementation KMCollectionViewComposedDelegate

#pragma mark - Public Methods

- (void)addDelegate:(KMCollectionViewDelegate *)delegate forGlobalSection:(NSInteger)section
{
    self.delegateMapping[@(section)] = delegate;
}

#pragma mark - Private Methods

- (NSMutableDictionary *)delegateMapping
{
    if (_delegateMapping == nil) {
        _delegateMapping = [NSMutableDictionary new];
    }
    return _delegateMapping;
}

- (id<UICollectionViewDelegate>)delegateForSection:(NSInteger)section
{
    return self.delegateMapping[@(section)];
}

- (id<UICollectionViewDelegate>)delegateForIndexPath:(NSIndexPath *)indexPath
{
    return [self delegateForSection:indexPath.section];
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *mappedIndexPath = [KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath];
    id<UICollectionViewDelegate> delegate = [self delegateForIndexPath:indexPath];
    CGSize sizeFromLayout = CGSizeZero;
    if ([delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        sizeFromLayout = [(id<UICollectionViewDelegateFlowLayout>)delegate collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:mappedIndexPath];
    }
    return sizeFromLayout;
}

@end
