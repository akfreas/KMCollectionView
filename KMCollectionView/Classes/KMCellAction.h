#import <Foundation/Foundation.h>

@interface KMCellAction : NSObject
- (id)initWithTarget:(id)target action:(SEL)selector title:(NSString *)title;
@end
