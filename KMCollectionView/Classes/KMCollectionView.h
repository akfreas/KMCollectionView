@import Foundation;
@import UIKit;

@interface KMCollectionView : UICollectionView
@property (nonatomic) BOOL reactToKeyboard;
@property (nonatomic) BOOL reactToOffsetChangesWhileReload;

- (void)addContentOffsetObserver:(void (^)(CGPoint))observer forKey:(NSString *)key;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated completion:(void(^)())completion;
- (void)removeContentOffsetObserverForKey:(NSString *)key;
@end
