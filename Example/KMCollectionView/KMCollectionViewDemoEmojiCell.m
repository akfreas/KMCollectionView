#import "KMCollectionViewDemoEmojiCell.h"
#import <PureLayout/PureLayout.h>
#import "Emoji.h"

@interface KMCollectionViewDemoEmojiCell ()

@property (nonatomic) UILabel *emoji;

@end

@implementation KMCollectionViewDemoEmojiCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addLabel];
        [self addLayoutConstraints];
        [self configureLabel];
//        self.contentView.backgroundColor = [UIColor redColor];
    }
    return self;
}


- (void)setCharacter:(NSString *)character
{
    _character = character;
    [self configureLabel];
}

- (void)configureLabel
{
    self.emoji.text = self.character;
}

- (void)addLabel
{
    self.emoji = [UILabel new];
    [self.contentView addSubview:self.emoji];
}

- (void)addLayoutConstraints
{
    [self.emoji autoCenterInSuperviewMargins];
}

@end
