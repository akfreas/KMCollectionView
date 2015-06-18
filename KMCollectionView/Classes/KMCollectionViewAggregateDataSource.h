#import "KMCollectionViewDataSource.h"

@interface KMCollectionViewAggregateDataSource : KMCollectionViewDataSource

- (NSInteger)globalSectionForDatasourceClass:(Class)dataSourceClass;
- (void)addDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)addDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section notifyBatchUpdate:(BOOL)notify;
- (void)insertDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource;
- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource notifyBatchUpdate:(BOOL)notify;
@end
