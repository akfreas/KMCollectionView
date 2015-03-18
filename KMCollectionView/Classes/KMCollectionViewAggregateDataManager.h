#import "KMCollectionViewDataManager.h"
@class KMCollectionViewDataSource;
@class KMCollectionViewAggregateDataSource;

@interface KMCollectionViewAggregateDataManager : KMCollectionViewDataManager 


- (void)linkAggregateDataSource:(KMCollectionViewAggregateDataSource *)aggregateDataSource;
- (void)linkDataSource:(KMCollectionViewDataSource *)dataSource;


- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forCorrespondingDataSource:(KMCollectionViewDataSource *)dataSource inGlobalSection:(NSInteger)section;
- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forGlobalSection:(NSInteger)section;
- (void)associateDataSource:(KMCollectionViewDataSource *)dataSource withManagerInGlobalSection:(NSInteger)section;

@end
