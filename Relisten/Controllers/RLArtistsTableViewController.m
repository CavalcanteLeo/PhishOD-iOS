//
//  RLArtistsTableViewController.m
//  PhishOD
//
//  Created by Alec Gorge on 6/19/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "RLArtistsTableViewController.h"

#import <ObjectiveSugar/ObjectiveSugar.h>

#import "RLArtistTabViewController.h"
#import "IGAPIClient.h"
#import "AppDelegate.h"
#import "RLSettingsViewController.h"
#import "PHODPersistence.h"
#import "RLArtistTodayViewController.h"
#import "RLPushPopAnimator.h"
#import "NowPlayingBarViewController.h"

typedef NS_ENUM(NSInteger, RLArtistsSections) {
    RLArtistsTodaySection,
	RLArtistsFeaturedSection,
	RLArtistsAllSection,
	RLArtistsSectionsCount
};

static NSArray *featuredArtists;

@interface RLArtistsTableViewController ()

@property (nonatomic) NSArray *featuredArtists;
@property (nonatomic) NSArray *artists;

@property (nonatomic) NSMutableArray *searchFeaturedArtists;
@property (nonatomic) NSMutableArray *searchArtists;

@property (nonatomic) BOOL shouldAutoshow;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic) RLPushPopAnimator *animator;

@end

@implementation RLArtistsTableViewController

+ (void)initialize {
	featuredArtists = @[@"Grateful Dead",
                        @"Dead & Company",
						@"Marco Benevento",
						@"Phish",
						@"Phil Lesh and Friends",
						@"String Cheese Incident",
						@"Umphrey's McGee",
						];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Relisten";
    self.shouldAutoshow = YES;

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithImage:[UIImage settingsNavigationIcon]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(showSettings)];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    self.animator = [[RLPushPopAnimator alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.shouldAutoshow) {
#ifndef SNAPSHOT
        IGAPIClient.sharedInstance.artist = [PHODPersistence.sharedInstance objectForKey:@"current_artist"];
#endif
        
        if(IGAPIClient.sharedInstance.artist != nil) {
            [self performSelector:@selector(presentArtistTabs:)
                       withObject:@(NO)
                       afterDelay:0.0];
        }
        
        self.shouldAutoshow = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [AppDelegate.sharedDelegate.navDelegate addBarToViewController: self];
    [AppDelegate.sharedDelegate.navDelegate fixForViewController:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    BOOL state = NowPlayingBarViewController.sharedInstance.shouldShowBar;
    NowPlayingBarViewController.sharedInstance.shouldShowBar = false;
    [AppDelegate.sharedDelegate.navDelegate addBarToViewController: self];
    [AppDelegate.sharedDelegate.navDelegate fixForViewController:self];
    NowPlayingBarViewController.sharedInstance.shouldShowBar = state;
}

- (void)showSettings {
    UINavigationController *navController = [UINavigationController.alloc initWithRootViewController:RLSettingsViewController.new];
    
    [self presentViewController:navController
                       animated:YES
                     completion:nil];
}

- (void)refresh:(id)sender {
    self.artists = [PHODPersistence.sharedInstance objectForKey:@"artists_alpha"];
    self.featuredArtists = [PHODPersistence.sharedInstance objectForKey:@"artists_featured"];
    
    if(self.artists != nil && self.featuredArtists != nil) {
        [self.tableView reloadData];
        [super refresh:sender];
    }
    
	[IGAPIClient.sharedInstance artists:^(NSArray *a) {
		self.artists = [a sortedArrayUsingComparator:^NSComparisonResult(IGArtist *obj1,
																		 IGArtist *obj2) {
			
			return [obj1.name compare:obj2.name
							  options:NSCaseInsensitiveSearch];
		}];
		
		self.featuredArtists = [featuredArtists map:^id(NSString *object) {
			return [self.artists find:^BOOL(IGArtist *artist) {
				return [artist.name isEqualToString:object];
			}];
		}];
        
        self.searchArtists = (NSMutableArray *)self.artists.mutableCopy;
        self.searchFeaturedArtists = (NSMutableArray *)self.featuredArtists.mutableCopy;
        
        [PHODPersistence.sharedInstance setObject:self.artists
                                           forKey:@"artists_alpha"];
        
        [PHODPersistence.sharedInstance setObject:self.featuredArtists
                                           forKey:@"artists_featured"];
		
		[self.tableView reloadData];
		[super refresh:sender];
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RLArtistsSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	if (self.artists) {
		if (section == RLArtistsFeaturedSection) {
			return self.searchFeaturedArtists.count;
		}
		else if(section == RLArtistsAllSection) {
			return self.searchArtists.count;
		}
        else if(section == RLArtistsTodaySection) {
            return 1;
        }
	}
	
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
	if (self.artists) {
		if (section == RLArtistsFeaturedSection) {
			return @"Featured";
		}
		else if(section == RLArtistsAllSection) {
			return [NSString stringWithFormat:@"All %ld artists", self.searchArtists.count];
		}
        else if(section == RLArtistsTodaySection) {
            return nil;
        }
	}
	
	return nil;
}

- (IGArtist *)artistForIndexPath:(NSIndexPath *)indexPath {
	IGArtist *artist = nil;
	
	if(indexPath.section == RLArtistsFeaturedSection) {
		artist = self.searchFeaturedArtists[indexPath.row];
	}
	else {
		artist = self.searchArtists[indexPath.row];
	}
	
	return artist;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	
	if(cell == nil) {
		cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleValue1
									reuseIdentifier:@"cell"];
	}
    
    if(indexPath.section == RLArtistsTodaySection) {
        cell.textLabel.text = @"Shows on this day in history";
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
	
	IGArtist *artist = [self artistForIndexPath:indexPath];
	
	cell.textLabel.text = artist.name;
	
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", artist.recordingCount];
    
    cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:MIN(cell.textLabel.font.pointSize, 30)];
    
    cell.detailTextLabel.font = [UIFont fontWithName:cell.detailTextLabel.font.fontName size:MIN(cell.detailTextLabel.font.pointSize, 28)];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath
							 animated:YES];
    
    if(indexPath.section == RLArtistsTodaySection) {
        RLArtistTodayViewController *vc = RLArtistTodayViewController.new;
        vc.showSelectionCallback = ^(IGTodayShow *show) {
            [self.navigationController popViewControllerAnimated:YES];
            
            IGAPIClient.sharedInstance.artist = [self.artists find:^BOOL(IGArtist *object) {
                return object.id == show.ArtistId;
            }];
            
            [PHODPersistence.sharedInstance setObject:IGAPIClient.sharedInstance.artist
                                               forKey:@"current_artist"];
            
            [self presentArtistTabs: @(YES) withShowDate:show.display_date];
        };
        
        [self.navigationController pushViewController:vc
                                             animated:YES];
        
        return;
    }
	
	IGAPIClient.sharedInstance.artist = [self artistForIndexPath:indexPath];
    
    [PHODPersistence.sharedInstance setObject:IGAPIClient.sharedInstance.artist
                                       forKey:@"current_artist"];

    [self presentArtistTabs: @(YES)];
}

- (void)presentArtistTabs:(NSNumber *)animated withShowDate:(NSString *)displaDate {
    RLArtistTabViewController *vc = RLArtistTabViewController.new;
    vc.autopresentDisplayDate = displaDate;
    
    vc.transitioningDelegate = self;
    
    AppDelegate.sharedDelegate.tabs = vc;
    
    [self presentViewController:vc animated:YES completion:^{
        UIScreenEdgePanGestureRecognizer *recognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        recognizer.edges = UIRectEdgeLeft;
        [vc.edgeView addGestureRecognizer:recognizer];
    }];
}

- (void)presentArtistTabs:(NSNumber *)animated {
    [self presentArtistTabs:animated
               withShowDate:nil];
}

- (void)handleGesture:(UIScreenEdgePanGestureRecognizer *)recognizer {
    self.animator.percentageDriven = YES;
    CGFloat progress = [recognizer translationInView:self.view].x / self.view.bounds.size.width / 2;
    progress = MIN(1.0, MAX(0.0, progress));
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        case UIGestureRecognizerStateChanged:
            [self.animator updateInteractiveTransition:progress];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            ([recognizer velocityInView:self.view].x < 0) ? [self.animator cancelInteractiveTransition] : [self.animator finishInteractiveTransition];
            self.animator.percentageDriven = NO;
            break;
        default:
            break;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.animator.dismissing = NO;
    return self.animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.animator.dismissing = YES;
    return self.animator;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.animator.percentageDriven ? self.animator : nil;
}

@end
