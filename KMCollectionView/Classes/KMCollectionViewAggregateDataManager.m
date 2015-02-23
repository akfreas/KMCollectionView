#import "KMCollectionViewAggregateDataManager.h"
#import "KMCollectionViewUtilities.h"
#import "KMCollectionViewAggregateDataSource.h"
#import "KMCollectionViewAggregateDataSource_private.h"

@interface KMCollectionViewAggregateDataManager () <UICollectionViewDelegateFlowLayout, KMCollectionViewDataManagerDelegate>
@property (nonatomic) NSMutableDictionary *dataManagerMap;
@property (nonatomic) NSMutableDictionary *dataSourceMap;

@property (nonatomic) NSMutableArray *dataSources;
@end

@implementation KMCollectionViewAggregateDataManager

- (void)linkAggregateDataSource:(KMCollectionViewAggregateDataSource *)aggregateDataSource
{
    aggregateDataSource.dataManager = self;
    for (KMCollectionViewDataSource *dataSource in [[aggregateDataSource dataSources] allValues]) {
        [self linkDataSource:dataSource];
    }
}

- (void)linkDataSource:(KMCollectionViewDataSource *)dataSource
{
    if (dataSource.dataManager == nil) {
        return;
    }
    dataSource.dataManager.delegate = self;
    [self.dataSources addObject:dataSource];
}

- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forCorrespondingDataSource:(KMCollectionViewDataSource *)dataSource inGlobalSection:(NSInteger)section
{
    [self addDataManager:dataManager forGlobalSection:section];
    [self associateDataSource:dataSource withManagerInGlobalSection:section];
}

- (void)associateDataSource:(KMCollectionViewDataSource *)dataSource withManagerInGlobalSection:(NSInteger)section
{
    if (self.dataManagerMap[@(section)] == nil) {
        return;
    }
    self.dataSourceMap[@(section)] = dataSource;
    dataSource.dataManager = self.dataManagerMap[@(section)];
}

- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forGlobalSection:(NSInteger)section
{
    self.dataManagerMap[@(section)] = dataManager;
    dataManager.delegate = self;
}

#pragma mark - Private Methods

- (NSMutableDictionary *)dataManagerMap
{
    if (_dataManagerMap == nil) {
        _dataManagerMap = [NSMutableDictionary new];
    }
    return _dataManagerMap;
}

- (NSMutableDictionary *)dataSourceMap
{
    if (_dataSourceMap == nil) {
        _dataSourceMap = [NSMutableDictionary new];
    }
    return _dataSourceMap;
}

- (KMCollectionViewDataSource *)dataSourceForIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView
{
    KMCollectionViewAggregateDataSource *aggregateDataSource = (KMCollectionViewAggregateDataSource *)collectionView.dataSource;
    KMCollectionViewDataSource *dataSource = [aggregateDataSource datasourceForIndexPath:indexPath];
    return dataSource;
}

- (KMCollectionViewDataManager *)dataManagerForIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView
{
    KMCollectionViewDataManager *manager;
    if ([collectionView.dataSource isKindOfClass:[KMCollectionViewAggregateDataSource class]]) {
        KMCollectionViewDataSource *dataSource = [self dataSourceForIndexPath:indexPath withCollectionView:collectionView];
        manager = dataSource.dataManager;
    }
    if (manager == nil) {
        manager = self.dataManagerMap[@(indexPath.section)];
    }
    return manager;
}

#pragma mark UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *mappedIndexPath = [KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath];
    KMCollectionViewDataManager *manager = [self dataManagerForIndexPath:indexPath withCollectionView:collectionView];
    if (manager != nil) {
        return [manager collectionView:collectionView shouldDeselectItemAtIndexPath:mappedIndexPath];
    }
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *mappedIndexPath = [KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath];
    KMCollectionViewDataManager *manager = [self dataManagerForIndexPath:indexPath withCollectionView:collectionView];
    if (manager != nil) {
        return [manager collectionView:collectionView shouldSelectItemAtIndexPath:mappedIndexPath];
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *mappedIndexPath = [KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath];
    KMCollectionViewDataManager *manager = [self dataManagerForIndexPath:indexPath withCollectionView:collectionView];
    if ([manager respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [manager collectionView:collectionView didSelectItemAtIndexPath:mappedIndexPath];
        KMCollectionViewDataSource *dataSource = [self dataSourceForIndexPath:indexPath withCollectionView:collectionView];
        if ([manager collectionView:collectionView shouldRefreshItemAfterSelectionAtIndexPath:mappedIndexPath]) {
            [dataSource notifyItemsRefreshedAtIndexPaths:@[mappedIndexPath]];
        }
    }
}

#pragma mark UICollectionViewFlowLayout
/*
 This code that helps with the collection view layout should really not be in this
 class.  In the future, it should be moved to the layout itself, where the layout can
 connect to the datasource and query these methods itself.
 */

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    UIEdgeInsets insets = UIEdgeInsetsEqualToEdgeInsets(mapping.edgeInsets, UIEdgeInsetsZero) == NO ? mapping.edgeInsets : UIEdgeInsetsZero;
    return insets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    CGFloat minimumSpacing = mapping.minimumInterItemSpacing;
    return minimumSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForIndexPath:indexPath];
    CGSize cellSize = mapping.size;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    } else if (mapping.options & KMCollectionViewCellMappingWidthAsPercentage) {
        cellSize.width = collectionView.frame.size.width * cellSize.width;
    }
    if (mapping.options & KMCollectionViewCellMappingHeightUndefined) {
        cellSize.height = 44.0f;
    } else if (mapping.options & KMCollectionViewCellMappingSquare) {
        cellSize.height = cellSize.width;
    }
    return cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    return mapping.minimumLineSpacing;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForHeaderInSection:section];
    CGSize cellSize = mapping? mapping.size : CGSizeZero;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    }
    return cellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForFooterInSection:section];
    CGSize cellSize = mapping? mapping.size : CGSizeZero;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    }
    return cellSize;
}

#pragma mark KMCollectionViewDataManagerDelegate

- (void)dataManager:(KMCollectionViewDataManager *)dataManager wantsToPerformViewAction:(KMDataManagerViewActionBlock)specialAction
{
    [self.delegate dataManager:dataManager wantsToPerformViewAction:specialAction];
}

@end
