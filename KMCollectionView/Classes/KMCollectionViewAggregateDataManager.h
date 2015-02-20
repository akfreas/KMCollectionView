#import "KMCollectionViewDataManager.h"
@class KMCollectionViewDataSource;
@class KMCollectionViewAggregateDataSource;

@interface KMCollectionViewAggregateDataManager : KMCollectionViewDataManager 


- (void)linkAggregateDataSource:(KMCollectionViewAggregateDataSource *)aggregateDataSource;
- (void)linkDataSource:(KMCollectionViewDataSource *)dataSource;


/* The following methods are deprecated in favor of the above method.
   Instead of relying on a manually set section for a datasource to be 
   associated with, the datasource will provide an instance of a datamanager.
   We can infer the datasource by accessing the collection view's
   datasource (which must be an aggregate source), and finally forwarding
   the collection view delegate method off to the manager that is exposed
   by that datasource.
*/
- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forCorrespondingDataSource:(KMCollectionViewDataSource *)dataSource inGlobalSection:(NSInteger)section __deprecated;
- (void)addDataManager:(KMCollectionViewDataManager *)dataManager forGlobalSection:(NSInteger)section __deprecated;
- (void)associateDataSource:(KMCollectionViewDataSource *)dataSource withManagerInGlobalSection:(NSInteger)section __deprecated;

@end
