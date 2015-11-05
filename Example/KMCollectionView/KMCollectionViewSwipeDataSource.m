#import "KMCollectionViewSwipeDataSource.h"
#import <ChameleonFramework/Chameleon.h>
#import "KMCollectionViewCell.h"
#import "KMCellAction.h"
#import <PureLayout/PureLayout.h>

@implementation KMCollectionViewSwipeDataSource


- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath
{
    static KMCollectionViewCellMapping *mapping;
    
    if (mapping == nil) {
        mapping = [KMCollectionViewCellMapping cellMappingWithIdentifier:@"SwipeCell" cellClass:[KMCollectionViewCell class] size:CGSizeMake(1.0, 44.0) options:KMCollectionViewCellMappingWidthAsPercentage];
    }
    return mapping;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];
    [collectionView registerClass:[KMCollectionViewCell class] forCellWithReuseIdentifier:@"SwipeCell"];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSArray<KMCellAction *> *)collectionView:(UICollectionView *)collectionView cellActionForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return @[[[KMCellAction alloc] initWithTarget:self action:@selector(deleteButtonTapped) title:@"Delete"]];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SwipeCell" forIndexPath:indexPath];
    
    UIView *v = [[UILabel alloc] initWithFrame:CGRectZero];
    [cell.contentView addSubview:v];
    [v autoPinEdgesToSuperviewEdges];
    return cell;
}

- (void)deleteButtonTapped
{
    
}

@end
