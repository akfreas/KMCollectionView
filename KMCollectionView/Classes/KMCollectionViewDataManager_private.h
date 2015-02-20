#import "KMCollectionViewDataManager.h"


@interface KMCollectionViewDataManager (Private)
@property (nonatomic) NSMutableDictionary *managedDataMap;
@property (nonatomic) NSMutableDictionary *actionMap;

- (void)save;
- (BOOL)actionExistsAtIndexPath:(NSIndexPath *)indexPath;
- (void)performActionAtIndexPath:(NSIndexPath *)indexPath;


@end
