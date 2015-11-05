#import <Foundation/Foundation.h>

@interface KMCellAction : NSObject

@property (weak, nonatomic, nullable) id target;
@property (nonatomic, nonnull) SEL action;
@property (nonatomic, nonnull) NSString *title;
@property (nonatomic, nullable) UIColor *color;


- (id __nonnull)initWithTarget:(id __nullable)target action:(SEL __nullable)selector title:(NSString * __nonnull)title;
@end
