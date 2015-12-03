//
//  KMCollectionHeaderView.m
//  Pods
//
//  Created by Matthias Friese on 03.12.15.
//
//

#import "KMCollectionHeaderView.h"
#import <PureLayout/PureLayout.h>

@interface KMCollectionHeaderView ()

@property (nonatomic) UILabel *label;

@end

@implementation KMCollectionHeaderView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self addLabel];
        [self addLayoutConstraints];
    }
    return self;
}

- (void)setTitleText:(NSString *)titleText
{
    _titleText = titleText;
    [self updateText];
}

- (void)setFontAttributes:(NSDictionary *)fontAttributes
{
    _fontAttributes = fontAttributes;
    [self updateText];
}


#pragma mark - private mehtods

- (void)addLabel
{
    self.label = [UILabel new];
    [self addSubview:self.label];
}

- (void)addLayoutConstraints
{
    [self.label autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:15.0];
    [self.label autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:15.0];
    [self.label autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
}

- (void)updateText
{
    if (self.titleText == nil) {
        self.label.text = nil;
        self.label.attributedText = nil;
    } else if (self.fontAttributes == nil) {
        self.label.text = self.titleText;
    } else {
        self.label.attributedText = [[NSAttributedString alloc] initWithString:self.titleText attributes:self.fontAttributes];
    }
}

@end
