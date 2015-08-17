#import "KMCollectionViewDataSource.h"

@interface KMCollectionViewAggregateDataSource : KMCollectionViewDataSource

- (NSInteger)numberOfSections;
- (NSInteger)globalSectionForDatasourceClass:(Class)dataSourceClass;
- (void)addDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)insertDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource;
- (void)removeAllDataSourcesWithBatchUpdate:(BOOL)notify;
- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource notifyBatchUpdate:(BOOL)notify;
@end
