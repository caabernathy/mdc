/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ViewController.h"
#import "AppDelegate.h"
#import "MyShareViewController.h"

@interface ViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *shareBookButton;
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (strong, nonatomic) NSArray *books;
@property (strong, nonatomic) NSMutableArray *bookViews;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIImageView *privacyImageView;
@property (weak, nonatomic) IBOutlet UIButton *createChallengeButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Set up book info
    
    // Make the book demo-ing image upload be mutable
    NSMutableDictionary *gameOfThronesBookObject =
    [[NSMutableDictionary alloc] initWithDictionary:@{
     @"type": @"books.book",
     @"fbsdk:create_object": @YES,
     @"title": @"A Game of Thrones",
     @"url": @"http://furious-mist-4378.herokuapp.com/books/a_game_of_thrones/",
     @"description": @"In the frozen wastes to the north of Winterfell, sinister and supernatural forces are mustering.",
     @"data": @{@"isbn": @"0-553-57340-3"}
     }];
    
    self.books = @[
                   @{@"image": [UIImage imageNamed:@"the_tipping_point.png"],
                     @"privacy": @YES,
                     @"object": @{
                             @"type": @"books.book",
                             @"fbsdk:create_object": @YES,
                             @"title": @"The Tipping Point",
                             @"url": @"http://furious-mist-4378.herokuapp.com/books/the_tipping_point/",
                             @"image": @"http://www.renderready.com/wp-content/uploads/2011/02/the_tipping_point.jpg",
                             @"description": @"How Little Things Can Make a Big Difference",
                             @"data": @{@"isbn": @"0-316-31696-2"}
                             }
                     },
                   @{@"image": [UIImage imageNamed:@"a_game_of_thrones.png"],
                     @"privacy": @YES,
                     @"object": gameOfThronesBookObject,
                     },
                   @{@"image": [UIImage imageNamed:@"catching_fire.png"],
                     @"privacy": @NO,
                     @"object": @"442064879213253"
                     },
                   @{@"image": [UIImage imageNamed:@"bloodline.png"],
                     @"privacy": @NO,
                     @"object": @"http://furious-mist-4378.herokuapp.com/books/bloodline.html"
                     },
                   ];
    
    self.scrollView.delegate = self;
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = self.books.count;
    self.bookViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.books.count; ++i) {
        self.bookViews[i] = [NSNull null];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.books.count,
                                             pagesScrollViewSize.height);
    [self loadVisiblePages];
    
    // Show the challenge button
    self.createChallengeButton.hidden = NO;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Share methods
- (IBAction)shareBookAction:(id)sender {
    // Find the page we're on to get at the current book info
    NSInteger page = self.pageControl.currentPage;
    
    // Make sure the user's logged in for creating user-owned objects
    if ([self.books[page][@"privacy"] boolValue] && !FBSession.activeSession.isOpen) {
        [[[UIAlertView alloc]
          initWithTitle:@""
          message:@"Please log in with Facebook to share."
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil, nil] show];
    } else {
        // Check if object image upload needed
        [self checkAndUploadBookImage];
        
        // Create an action
        id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
        
        // Connect the action to the defined object
        action[@"book"] = self.books[page][@"object"];
        
        //        // Show pre-selection of a place and a friend
        //        id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
        //        [place setId:@"191206170926721"]; // Facebook Menlo Park
        //        [action setPlace:place]; // set place tag
        //        [action setTags:@[@"100003086810435"]]; // set user tags
        
        // Enable the Share Dialog beta feature
        [FBSettings enableBetaFeature:FBBetaFeaturesOpenGraphShareDialog];
        
        // Show the share dialog to publish the book read action
        FBAppCall *call =
        [FBDialogs presentShareDialogWithOpenGraphAction:action
                                              actionType:@"books.reads"
                                     previewPropertyName:@"book"
                                                 handler:
         ^(FBAppCall *call, NSDictionary *results, NSError *error) {
             if(error) {
                 NSLog(@"Error: %@", error.description);
             } else {
                 NSLog(@"Success!");
             }
         }];
        
        // Backup share via a customized UI
        if (!call && [self.books[page][@"object"] isKindOfClass:[NSDictionary class]]) {
            // Fallback to customized share UI
            MyShareViewController *viewController =
            [[MyShareViewController alloc] initWithItem:self.books[page]
                                             objectType:@"book"
                                             actionType:@"books.reads"];
            [self presentViewController:viewController
                               animated:YES
                             completion:nil];
        }
    }
    
}

- (IBAction)createChallengeAction:(id)sender {
    NSDictionary* object = @{
                             @"fbsdk:create_object": @YES,
                             @"type": @"mobdevcon:challenge",
                             @"title": @"Summer Reading Challenge",
                             @"url": @"https://furious-mist-4378.herokuapp.com/challenge/summer_2013/",
                             @"image": @"https://furious-mist-4378.herokuapp.com/challenge/summer_reading_challenge.png",
                             @"description": @"Read as many great books as you can over the summer."
                             };
    
    
    
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    action[@"challenge"] = object; // set action's challenge property
    
    //    //id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
    //    //[place setId:@"191206170926721"]; // Facebook Menlo Park
    //    //[action setPlace:place]; // set place tag
    //
    //    //[action setTags:@[@"100003086810435"]]; // set user tags
    
    // Enable the Share Dialog beta feature
    [FBSettings enableBetaFeature:FBBetaFeaturesOpenGraphShareDialog];
    
    // Show the share dialog to publish the create challenge action
    FBAppCall *call = [FBDialogs presentShareDialogWithOpenGraphAction:action
                                                            actionType:@"mobdevcon:create"
                                                   previewPropertyName:@"challenge"
                                                               handler:
                       ^(FBAppCall *action, NSDictionary *results, NSError *error) {
                           if(error) {
                               NSLog(@"Error: %@", error.description);
                           } else {
                               NSLog(@"Success!");
                           }
                       }];
    if (!call) {
        // Fallback to customized share UI
        NSDictionary *challenge = @{
                                    @"image": [UIImage imageNamed:@"summer_reading_challenge.png"],
                                    @"privacy": @YES,
                                    @"object": object
                                    };
        MyShareViewController *viewController =
        [[MyShareViewController alloc] initWithItem:challenge
                                         objectType:@"challenge"
                                         actionType:@"mobdevcon:create"];
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - Upload image methods
/*
 * Check if the book's image needs to be uploaded
 */
- (void) checkAndUploadBookImage
{
    NSInteger page = self.pageControl.currentPage;
    // Check if object image upload needed
    if ([self.books[page][@"object"] isKindOfClass:[NSDictionary class]]) {
        if (!self.books[page][@"object"][@"image"]) {
            // Ask for publish_actions permissions in context
            if ([FBSession.activeSession.permissions
                 indexOfObject:@"publish_actions"] == NSNotFound) {
                // No permissions found in session, ask for it
                [FBSession.activeSession
                 requestNewPublishPermissions:
                 [NSArray arrayWithObject:@"publish_actions"]
                 defaultAudience:FBSessionDefaultAudienceFriends
                 completionHandler:^(FBSession *session, NSError *error) {
                     if (!error) {
                         // If permissions granted, publish the image
                         [self publishBookImage:self.books[page][@"image"]];
                     }
                 }];
            } else {
                // If permissions present, publish the story
                [self publishBookImage:self.books[page][@"image"]];
            }
            return;
        }
    }
}

/*
 * Upload the image to the staging resources
 */
- (void) publishBookImage:(UIImage *)image {
    [FBSettings setLoggingBehavior:
     [NSSet setWithObjects:FBLoggingBehaviorFBRequests,
      FBLoggingBehaviorFBURLConnections,
      nil]];
    [FBRequestConnection startForUploadStagingResourceWithImage:image
                                              completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (error) {
             NSLog(@"%@", error);
         } else {
             NSInteger page = self.pageControl.currentPage;
             // Set the book's image URL to the staging uri
             self.books[page][@"object"][@"image"] = result[@"uri"];
             // Publish the story
             [self shareBookAction:nil];
             [FBSettings setLoggingBehavior:nil];
         }
     }];
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
}

/*
 * When user info fetched personalize the experience
 */
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user
{
}

#pragma mark - Page control helper methods
- (void)loadPage:(NSInteger)page {
    if (page < 0 || page >= self.books.count) {
        // If it's outside the range of what you have to display, then do nothing
        return;
    }
    
    UIView *pageView = self.bookViews[page];
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        UIImageView *newBookView = [[UIImageView alloc] initWithImage:self.books[page][@"image"]];
        newBookView.contentMode = UIViewContentModeScaleAspectFit;
        newBookView.frame = frame;
        [self.scrollView addSubview:newBookView];
        self.bookViews[page] = newBookView;
    }
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= self.books.count) {
        // If it's outside the range of what you have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *bookView = self.bookViews[page];
    if ((NSNull*)bookView != [NSNull null]) {
        [bookView removeFromSuperview];
        self.bookViews[page] = [NSNull null];
    }
}

- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Update the page control
    self.pageControl.currentPage = page;
    
    // Work out which pages you want to load
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePage:i];
    }
    
	// Load pages in our range
    for (NSInteger i=firstPage; i<=lastPage; i++) {
        [self loadPage:i];
    }
    
	// Purge anything after the last page
    for (NSInteger i=lastPage+1; i<self.books.count; i++) {
        [self purgePage:i];
    }
    
    // Set the privacy image
    if ([self.books[page][@"privacy"] boolValue]) {
        self.privacyImageView.hidden = NO;
    } else {
        self.privacyImageView.hidden = YES;
    }
}

#pragma mark - ScrollView delegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages that are now on screen
    [self loadVisiblePages];
}

- (void)viewDidUnload {
    [self setCreateChallengeButton:nil];
    [super viewDidUnload];
}
@end