#import <UIKit/UIKit.h>
#import "KMCellAction.h"


@interface KMCellActionView : UIView

- (void)addSubviewsForActions:(NSArray <KMCellAction *>*)actions;

@end
