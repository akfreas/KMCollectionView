#import "KMCellActionView.h"
#import <PureLayout/PureLayout.h>


@interface KMCellActionView ()
@property (nonatomic) NSArray <UIButton *> *buttons;
@end

@implementation KMCellActionView

- (void)addSubviewsForActions:(NSArray<KMCellAction *> *)actions
{
    __block UIView *lastView = self;
    ALEdge edge = ALEdgeLeft;
    [actions enumerateObjectsUsingBlock:^(KMCellAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        button.backgroundColor = obj.color;
        [button addTarget:obj.target action:obj.action forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:obj.title forState:UIControlStateNormal];
        
        [self addSubview:button];
        
        [button autoPinEdge:ALEdgeLeft toEdge:edge ofView:lastView];
        [button autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
        lastView = button;
    }];
    
    [lastView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
    
}

@end
