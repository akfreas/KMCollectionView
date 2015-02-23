#import "KMCollectionViewDemoEmojiCell.h"
#import <PureLayout/PureLayout.h>
#import "Emoji.h"

@interface KMCollectionViewDemoEmojiCell ()

@property (nonatomic) UILabel *emoji;

@end

@implementation KMCollectionViewDemoEmojiCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addLabel];
        [self addLayoutConstraints];
        [self configureLabel];
    }
    return self;
}


- (void)setCharacter:(int)character
{
    _character = character;
    [self configureLabel];
}

- (void)configureLabel
{
    self.emoji.text = [Emoji emojiWithCode:self.character];
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
