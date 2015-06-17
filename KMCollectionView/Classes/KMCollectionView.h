@import Foundation;
@import UIKit;

@interface KMCollectionView : UICollectionView
@property (nonatomic) BOOL reactToKeyboard;

- (void)addContentOffsetObserver:(void (^)(CGPoint))observer forKey:(NSString *)key;
- (void)removeContentOffsetObserverForKey:(NSString *)key;
@end
