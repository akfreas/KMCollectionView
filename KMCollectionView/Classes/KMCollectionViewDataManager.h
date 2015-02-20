#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <objc/objc.h>

@protocol KMCollectionViewDataManagerDelegate;

typedef void(^KMDataManagerViewActionBlock)(UIViewController *controller, BOOL canPerformAction);

@interface KMCollectionViewDataManager : NSObject <UICollectionViewDelegate>

@property (nonatomic, readonly) NSInteger itemCount;
@property (nonatomic, weak) id<KMCollectionViewDataManagerDelegate> delegate;

- (void)resetManagedData;

- (void)addManagedData:(id)data atIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)appendManagedData:(id)data inSection:(NSInteger)section;
- (void)removeManagedDataAtIndexPath:(NSIndexPath *)indexPath;
- (void)saveAllSectionsWithCompletion:(void(^)(NSArray *, KMCollectionViewDataManager *))completion;
- (void)saveSection:(NSInteger)section withCompletion:(void (^)(NSArray *, KMCollectionViewDataManager *))completion;

- (void)addViewAction:(KMDataManagerViewActionBlock)action forIndexPath:(NSIndexPath *)indexPath;
- (void)removeViewActionAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveViewActionAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView shouldRefreshItemAfterSelectionAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol KMCollectionViewDataManagerDelegate <NSObject>

- (void)dataManager:(KMCollectionViewDataManager *)dataManager wantsToPerformViewAction:(KMDataManagerViewActionBlock)specialAction;

@end
