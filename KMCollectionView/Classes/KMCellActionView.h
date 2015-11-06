#import <UIKit/UIKit.h>
#import "KMCellAction.h"


@interface KMCellActionView : UIView

- (id)initWithCell:(UICollectionViewCell *)cell;

- (void)addSubviewsForActions:(NSArray <KMCellAction *>*)actions;

@end
