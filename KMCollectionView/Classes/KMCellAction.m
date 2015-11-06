#import "KMCellAction.h"

@interface KMCellAction ()


@end

@implementation KMCellAction

- (id)initWithTarget:(id)target action:(SEL)action title:(NSString *)title
{
    self = [super init];
    if (self) {
        _target = target;
        _action = action;
        _title = title;
    }
    return self;
}

- (UIColor *)color
{
    if (_color == nil) {
        return [UIColor redColor];
    }
    return _color;
}

@end
