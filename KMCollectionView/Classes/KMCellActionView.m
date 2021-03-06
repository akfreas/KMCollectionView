#import "KMCellActionView.h"
#import <PureLayout/PureLayout.h>


@interface KMCellActionView ()
@property (nonatomic, nullable) NSArray <UIButton *> *buttons;
@property (nonatomic, nonnull) UICollectionViewCell *cell;
@end

@implementation KMCellActionView


- (id)initWithCell:(UICollectionViewCell *)cell
{
    self = [self initWithFrame:CGRectZero];
    if (self) {
        self.cell = cell;
    }
    [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)addSubviewsForActions:(NSArray<KMCellAction *> *)actions
{
    __block UIView *lastView = self;
    __block ALEdge edge = ALEdgeLeft;
    NSInteger actionCount = [actions count];
    [actions enumerateObjectsUsingBlock:^(KMCellAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *wrapper = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:wrapper];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [wrapper addSubview:button];
        button.tag = idx;
        button.backgroundColor = obj.color;
        [button addTarget:self.cell action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:obj.title forState:UIControlStateNormal];
        [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [button setContentHuggingPriority:UILayoutPriorityRequired - 10 forAxis:UILayoutConstraintAxisHorizontal];
        
        [button autoAlignAxis:ALAxisHorizontal toSameAxisOfView:wrapper];
        [button autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:wrapper];
        [button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:wrapper];
        [button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:wrapper];
        
        [wrapper autoPinEdge:ALEdgeLeft toEdge:edge ofView:lastView];
        [wrapper autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [wrapper autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
        edge = ALEdgeRight;
        [NSLayoutConstraint autoCreateAndInstallConstraints:^{
            NSLayoutConstraint *c = [wrapper autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:1/
                                     actionCount];
            c.priority = UILayoutPriorityDefaultHigh;
        }];
        
        wrapper.clipsToBounds = YES;
        lastView = wrapper;
    }];
    
    [lastView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
}

@end
