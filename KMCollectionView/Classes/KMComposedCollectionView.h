#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class KMCollectionViewDataSource;

/// Maps global sections to local sections for a given data source
@interface KMComposedMapping : NSObject <NSCopying>

- (instancetype)initWithDataSource:(KMCollectionViewDataSource *)dataSource;

/// The data source associated with this mapping
@property (nonatomic, strong) KMCollectionViewDataSource * dataSource;

/// The number of sections in this mapping
@property (nonatomic, readonly) NSInteger sectionCount;

/// Return the local section for a global section
- (NSUInteger)localSectionForGlobalSection:(NSUInteger)globalSection;

/// Return the global section for a local section
- (NSUInteger)globalSectionForLocalSection:(NSUInteger)localSection;

/// Return a local index path for a global index path
- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath;

/// Return a global index path for a local index path
- (NSIndexPath *)globalIndexPathForLocalIndexPath:(NSIndexPath *)localIndexPath;

/// Return an array of local index paths from an array of global index paths
- (NSArray *)localIndexPathsForGlobalIndexPaths:(NSArray *)globalIndexPaths;

/// Return an array of global index paths from an array of local index paths
- (NSArray *)globalIndexPathsForLocalIndexPaths:(NSArray *)localIndexPaths;

/// Update the mapping of local sections to global sections.
- (NSUInteger)updateMappingsStartingWithGlobalSection:(NSUInteger)globalSection;

@end

@interface KMComposedCollectionView : NSObject

- (id)initWithView:(UICollectionView *)view mapping:(KMComposedMapping *)mapping;

@property (nonatomic, readonly) UICollectionView *wrappedView;
@property (nonatomic, retain) KMComposedMapping *mapping;

@end
