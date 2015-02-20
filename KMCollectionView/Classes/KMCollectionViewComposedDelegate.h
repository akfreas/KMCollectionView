#import "KMCollectionViewDelegate.h"

@interface KMCollectionViewComposedDelegate : KMCollectionViewDelegate
- (void)addDelegate:(KMCollectionViewDelegate *)delegate forGlobalSection:(NSInteger)section;
@end
