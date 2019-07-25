//
//  ProjectObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <ActionSheetPicker-3.0/ActionSheetPicker.h>
#import <FontAwesomeKit/FAKIonicons.h>

#import "ProjectObservationsViewController.h"
#import "ProjectObservationHeaderView.h"
#import "Analytics.h"
#import "ObsFieldSimpleValueCell.h"
#import "ObsFieldLongTextValueCell.h"
#import "ProjectObsFieldViewController.h"
#import "TaxaSearchViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "ExploreTaxonRealm.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"
#import "UIColor+INaturalist.h"
#import "InsetLabel.h"
#import "ProjectsAPI.h"
#import "ExploreProject.h"
#import "ExploreProjectRealm.h"
#import "ExploreProjectObservation.h"
#import "ExploreObservationFieldValueRealm.h"

static NSString *SimpleFieldIdentifier = @"simple";
static NSString *LongTextFieldIdentifier = @"longtext";

@interface ProjectObservationsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TaxaSearchViewControllerDelegate> {
    UIToolbar *_keyboardToolbar;
}

@property RKObjectLoader *loader;
@property NSIndexPath *taxaSearchIndexPath;
@property UITapGestureRecognizer *tapAwayGesture;
@property (readonly) UIToolbar *keyboardToolbar;
@property RLMResults *joinedInatProjects;
@property RLMNotificationToken *updateToken;
@property NSArray *readonlyObservationProjects;
@end

@implementation ProjectObservationsViewController


- (NSArray *)joinedProjectSortDescriptors {
    return @[
             [RLMSortDescriptor sortDescriptorWithKeyPath:@"type" ascending:NO],
             [RLMSortDescriptor sortDescriptorWithKeyPath:@"title" ascending:YES],
             ];
}

- (ProjectsAPI *)projectsAPI {
    static ProjectsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ProjectsAPI alloc] init];
    });
    return _api;
}

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isReadOnly) {
        self.title = NSLocalizedString(@"Projects", nil);
    } else {
        self.title = NSLocalizedString(@"Choose Projects", @"title for project observations chooser");
    }
    
    if (!self.isReadOnly) {
        // if we're not readonly, ie this is this user's observation,
        // then we need to show them some help about why some projects
        // have a toggle and some don't.
        self.tableView.tableHeaderView = ({
            InsetLabel *label = [InsetLabel new];
            label.insets = UIEdgeInsetsMake(10, 10, 10, 10);
            label.text = NSLocalizedString(@"Please note: Observations will be automatically included in a collection project if they meet its requirements.",
                                           @"helpful note about observations and collection projects on the screen where you can add observations to projects.");
            label.numberOfLines = 0;
            label.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
            label;
        });
        [self.tableView.tableHeaderView sizeToFit];
    }
    
    self.navigationItem.leftBarButtonItem = ({
        FAKIcon *backIcon = [FAKIonIcons iosArrowBackIconWithSize:34];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[backIcon imageWithSize:CGSizeMake(14, 34)]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(backPressed:)];
        
        item;
    });
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView registerClass:[ObsFieldSimpleValueCell class] forCellReuseIdentifier:SimpleFieldIdentifier];
    [self.tableView registerClass:[ObsFieldLongTextValueCell class] forCellReuseIdentifier:LongTextFieldIdentifier];
    
    if (self.isReadOnly) {
        [self loadReadonlyObservationProjects];
    } else {
        [self loadJoinedProjectsForUser];
    }
}

- (void)loadReadonlyObservationProjects {
    if (self.observation.projectObservations.count > 0) {
        __weak typeof(self) weakSelf = self;
        [[self projectsAPI] projectsWithIds:self.observation.projectIds handler:^(NSArray *results, NSInteger count, NSError *error) {
            weakSelf.readonlyObservationProjects = results;
            [weakSelf.tableView reloadData];
        }];
    }
}

- (void)loadJoinedProjectsForUser {
    // TODO: this should just be a list field on the user object?
    self.joinedInatProjects = [[ExploreProjectRealm joinedProjects] sortedResultsUsingDescriptors:[self joinedProjectSortDescriptors]];
    __weak typeof(self)weakSelf = self;
    self.updateToken = [self.joinedInatProjects addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        [weakSelf.tableView reloadData];
    }];
    
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.loginController isLoggedIn]) {
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            if (!me) { return; }
            
            __weak typeof(self) weakSelf = self;
            [[self projectsAPI] joinedProjectsUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                [[ExploreProjectRealm allObjects] setValue:@(false) forKey:@"joined"];
                [realm commitWriteTransaction];
                
                for (ExploreProject *project in results) {
                    ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
                    epr.joined = YES;
                    [realm beginWriteTransaction];
                    [realm addOrUpdateObject:epr];
                    [realm commitWriteTransaction];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    [self.updateToken invalidate];
}

#pragma mark - UIBarButton targets

- (void)backPressed:(UIBarButtonItem *)button {
    
    if (self.isReadOnly) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    // end editing on any rows
    [self.tableView endEditing:YES];
    
    // save the ofvs
    [self saveVisibleObservationFieldValues];
    
    NSString *projectNameFailingValidation = nil;
    NSString *projectFieldFailingValidation = nil;
    
    BOOL validated = [self validateProjectObservationsForObservation:self.observation
                                                       failedProject:&projectNameFailingValidation
                                                         failedField:&projectFieldFailingValidation];
    
    if (validated) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"'%@' requires that you fill out the '%@' field.",nil),
                         projectNameFailingValidation,
                         projectFieldFailingValidation];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Missing Required Field",nil)
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - ProjectObs & OFV helpers

- (BOOL)validateProjectObservationsForObservation:(Observation *)observation
                                    failedProject:(out NSString **)failedProject
                                      failedField:(out NSString **)failedField {
    
    /*
     TODO: realm
    for (ProjectObservation *po in self.observation.sortedProjectObservations) {
        for (ProjectObservationField *pof in po.project.sortedProjectObservationFields) {
            if (pof.required.boolValue) {
                ObservationFieldValue *ofv = [[self.observation.observationFieldValues objectsPassingTest:^BOOL(ObservationFieldValue *obj, BOOL *stop) {
                    return [obj.observationField isEqual:pof.observationField];
                }] anyObject];
                if (!ofv || ofv.value == nil || ofv.value.length == 0) {
                    *failedProject = pof.project.title;
                    *failedField = pof.observationField.name;
                    
                    return false;
                }
            }
        }
    }
     */
    
    return true;
}

- (void)saveVisibleObservationFieldValues {
    if (self.isReadOnly) {
        return;
    }
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        /*
         TODO: realm
        Project *project = [self projectForSection:indexPath.section];
        ProjectObservationField *pof = [project sortedProjectObservationFields][indexPath.item];
        ObservationField *field = pof.observationField;
        
        ObservationFieldValue *ofv = [self.observation valueWithObservationFieldId:pof.observationFieldID.integerValue];
        if (ofv) {
            if (![ofv.value isEqualToString:[self currentValueForIndexPath:indexPath]]) {
                ofv.value = [self currentValueForIndexPath:indexPath];
                ofv.localUpdatedAt = [NSDate date];
            }
        } else {
            ObservationFieldValue *ofv = [ObservationFieldValue object];
            ofv.observationField = field;
            ofv.observation = self.observation;
            ofv.value = [self currentValueForIndexPath:indexPath];
            ofv.localUpdatedAt = [NSDate date];
        }
         */
    }
    
    NSError *error;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        // TODO: log it at least, also notify the user
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.superview.superview isKindOfClass:[ObsFieldSimpleValueCell class]]) {
        // this textfield needs to be cleared and the value set
        ObsFieldSimpleValueCell *cell = (ObsFieldSimpleValueCell *)textField.superview.superview;
        cell.valueLabel.text = textField.text;
        [textField removeFromSuperview];
        cell.valueLabel.hidden = NO;
    }
    [self saveVisibleObservationFieldValues];
}

- (void)tapAway:(UITapGestureRecognizer *)gesture {
    [gesture.view endEditing:YES];
    [gesture.view removeGestureRecognizer:gesture];
}

- (UIToolbar *)keyboardToolbar {
    if (!_keyboardToolbar) {
        _keyboardToolbar = [[UIToolbar alloc] init];
        _keyboardToolbar.barStyle = UIBarStyleDefault;
        [_keyboardToolbar sizeToFit];

        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(keyboardDone)];
        _keyboardToolbar.items = @[ flex, done ];
    }
    
    return _keyboardToolbar;
}

- (void)keyboardDone {
    [self.tableView endEditing:YES];
}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [textField setInputAccessoryView:self.keyboardToolbar];
    return YES;
}

#pragma mark - TaxaSearchViewControllerDelegate

- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon chosenViaVision:(BOOL)visionFlag {
    [self.navigationController popToViewController:self animated:YES];
    
    if (!self.taxaSearchIndexPath) { return; }
    
    ExploreProjectRealm *project = [self projectForSection:self.taxaSearchIndexPath.section];
    /*
     TODO: realm
    ProjectObservationField *field = [project sortedProjectObservationFields][self.taxaSearchIndexPath.item];
    
    ObservationFieldValue *ofv = [self.observation valueWithObservationFieldId:field.observationFieldID.integerValue];
    if (ofv) {
        ofv.value = [NSString stringWithFormat:@"%ld", (long)taxon.taxonId];
        ofv.localUpdatedAt = [NSDate date];
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ self.taxaSearchIndexPath ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    self.taxaSearchIndexPath = nil;
    [self saveVisibleObservationFieldValues];
     */
}

- (void)taxaSearchViewControllerCancelled {
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - UITableView delegate & datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObservationFieldRealm *field = [project fields][indexPath.item];
    
    if ([[ExploreProjectObservationField textFieldDataTypes] containsObject:field.observationField.dataType]) {
        if (field.observationField.allowedValues.count > 1) {
            ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
            [self configureSimpleCell:cell forObsField:field];
            return cell;
        } else {
            ObsFieldLongTextValueCell *cell = [tableView dequeueReusableCellWithIdentifier:LongTextFieldIdentifier];
            [self configureLongTextCell:cell forObsField:field];
            return cell;
        }
    } else if ([field.observationField.dataType isEqualToString:@"numeric"]) {
        ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
        [self configureSimpleCell:cell forObsField:field];
        return cell;
    } else if ([field.observationField.dataType isEqualToString:@"date"] || [field.observationField.dataType isEqualToString:@"datetime"]) {
        ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
        [self configureSimpleCell:cell forObsField:field];
        return cell;
    } else if ([field.observationField.dataType isEqualToString:@"time"]) {
        ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
        [self configureSimpleCell:cell forObsField:field];
        return cell;
    } else if ([field.observationField.dataType isEqualToString:@"taxon"]) {
        ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
        [self configureSimpleCell:cell forObsField:field];
        return cell;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ExploreProjectRealm *project = [self projectForSection:section];

    BOOL projectIsSelected = [self projectIsSelected:project];
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    
    UINib *nib = [UINib nibWithNibName:@"ProjectObservationHeaderView" bundle:[NSBundle mainBundle]];
    ProjectObservationHeaderView *header = [[nib instantiateWithOwner:nil options:nil] firstObject];
    header.frame = CGRectMake(0, 0, tableView.bounds.size.width, height);
    header.projectTitleLabel.text = project.title;
    header.projectTypeLabel.text = [project titleForTypeOfProject];
    
    if (self.isReadOnly) {
        header.selectedSwitch.hidden = YES;
        header.backgroundColor = [UIColor whiteColor];
    } else if (project.type == ExploreProjectTypeUmbrella || project.type == ExploreProjectTypeCollection) {
        header.selectedSwitch.hidden = YES;
        header.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
    } else {
        header.selectedSwitch.hidden = NO;
        [header.selectedSwitch setOn:projectIsSelected animated:NO];
        header.selectedSwitch.tag = section;
        [header.selectedSwitch addTarget:self action:@selector(selectedChanged:) forControlEvents:UIControlEventValueChanged];
        header.backgroundColor = [UIColor whiteColor];
    }
    
    if (project.iconUrl) {
        header.projectThumbnailImageView.backgroundColor = [UIColor clearColor];
        header.projectThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        [header.projectThumbnailImageView setImageWithURL:project.iconUrl];
    } else {
        // use standard projects icon
        header.projectThumbnailImageView.backgroundColor = [UIColor colorWithHexString:@"#cccccc"];

        FAKIcon *briefcase = [FAKIonIcons iosBriefcaseOutlineIconWithSize:16.0f];
        [briefcase addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        [header.projectThumbnailImageView setImage:[briefcase imageWithSize:CGSizeMake(16, 16)]];
        header.projectThumbnailImageView.contentMode = UIViewContentModeCenter;
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 55;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObservationFieldRealm *field = [project fields][indexPath.item];

    UIFont *fieldFont = field.required ? [UIFont boldSystemFontOfSize:17] : [UIFont systemFontOfSize:17];

    
    if ([[ExploreProjectObservationField textFieldDataTypes] containsObject:field.observationField.dataType] && field.observationField.allowedValues.count == 1) {
        return [self heightForLongTextProjectField:field inTableView:tableView font:fieldFont];
    } else {
        return [self heightForSimpleProjectField:field inTableView:tableView font:fieldFont];
    }
    
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isReadOnly) {
        // only show project in readonly mode, for now
        return 0;
    }
    
    ExploreProjectRealm *project = [self projectForSection:section];
    if (project.type == ExploreProjectTypeUmbrella || project.type == ExploreProjectTypeCollection) {
        // only show new style projects in readonly mode
        return 0;
    }
    
    if ([self projectIsSelected:project]) {
        return project.fields.count;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isReadOnly) {
        return self.readonlyObservationProjects.count;
    } else {
        return self.joinedInatProjects.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isReadOnly) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    if (project.type == ExploreProjectTypeUmbrella || project.type == ExploreProjectTypeCollection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    ExploreProjectObservationFieldRealm *pof = [project fields][indexPath.item];
    ExploreObservationFieldRealm *field = [pof observationField];
    ExploreObservationFieldValueRealm *obsFieldValue = nil;
    for (ExploreObservationFieldValueRealm *ofv in self.observation.observationFieldValues) {
        if (ofv.fieldId == field.fieldId) {
            obsFieldValue = ofv;
            break;
        }
    }
    
    NSInteger initialSelection = 0;
    
    if (obsFieldValue) {
        initialSelection = [field.allowedValues indexOfObject:obsFieldValue.value];
    }
    
    if ([[ExploreProjectObservationField textFieldDataTypes] containsObject:field.dataType] && field.allowedValues.count > 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        ProjectObsFieldViewController *pofVC = [[ProjectObsFieldViewController alloc] initWithNibName:nil bundle:nil];
        
        /*
         TODO: realm
        pofVC.projectObsField = field;
        pofVC.obsFieldValue = [[field.observationField.observationFieldValues objectsPassingTest:^BOOL(ObservationFieldValue *ofv, BOOL *stop) {
            return [ofv.observation isEqual:self.observation];
        }] anyObject];
         */
        
        [self.navigationController pushViewController:pofVC animated:YES];

    } else if ([[ExploreProjectObservationField textFieldDataTypes] containsObject:field.dataType]) {
        // free text
        
        // deselect
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // activate the textfield
        ObsFieldLongTextValueCell *cell = (ObsFieldLongTextValueCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
        
        self.tapAwayGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAway:)];
        [self.tableView addGestureRecognizer:self.tapAwayGesture];
        
    } else if ([field.dataType isEqualToString:@"numeric"]) {
        // numeric text entry
        
        // deselect
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        // setup a textfield above the label
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.valueLabel.hidden = YES;
        
        UITextField *tf = [[UITextField alloc] initWithFrame:cell.valueLabel.frame];
        tf.keyboardType = UIKeyboardTypeDecimalPad;
        tf.textAlignment = NSTextAlignmentRight;
        tf.returnKeyType = UIReturnKeyDone;
        tf.text = cell.valueLabel.text;
        tf.delegate = self;
        [cell.contentView addSubview:tf];
        
        [tf becomeFirstResponder];
        
        self.tapAwayGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAway:)];
        [self.tableView addGestureRecognizer:self.tapAwayGesture];

    } else if ([field.dataType isEqualToString:@"taxon"]) {
        // taxon picker
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        TaxaSearchViewController *search = [storyboard instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
        search.hidesDoneButton = YES;
        search.delegate = self;
        // only prime the query if there's a placeholder, not a taxon)
        if (self.observation.speciesGuess && ! self.observation.taxon) {
            search.query = self.observation.speciesGuess;
        }
        [self.navigationController pushViewController:search animated:YES];
        
        // stash the selected index path so we know what ofv to update
        self.taxaSearchIndexPath = indexPath;
        
    } else if ([field.dataType isEqualToString:@"date"] || [field.dataType isEqualToString:@"datetime"]) {
        // date field
        
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        static NSDateFormatter *dateFormatter;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"dd MMM yyyy HH:mm:ss ZZZ";
        }
        NSDate *date;
        if (cell.valueLabel.text && cell.valueLabel.text.length > 0) {
            date = [dateFormatter dateFromString:cell.valueLabel.text];
        }
        if (!date) {
            date = [NSDate date];
        }
        
        __weak typeof(self) weakSelf = self;
        [[[ActionSheetDatePicker alloc] initWithTitle:field.name
                                       datePickerMode:UIDatePickerModeDateAndTime
                                         selectedDate:date
                                            doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                NSDate *date = (NSDate *)selectedDate;
                                                cell.valueLabel.text = [dateFormatter stringFromDate:date];
                                                [weakSelf saveVisibleObservationFieldValues];
                                         } cancelBlock:nil
                                               origin:self.view] showActionSheetPicker];
        
    } else if ([field.dataType isEqualToString:@"time"]) {
        
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        static NSDateFormatter *dateFormatter;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"HH:mm:ss";
        }
        NSDate *date;
        if (cell.valueLabel.text && cell.valueLabel.text.length > 0) {
            date = [dateFormatter dateFromString:cell.valueLabel.text];
        }
        if (!date) {
            date = [NSDate date];
        }
        
        __weak typeof(self) weakSelf = self;
        [[[ActionSheetDatePicker alloc] initWithTitle:field.name
                                       datePickerMode:UIDatePickerModeTime
                                         selectedDate:date
                                            doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                NSDate *date = (NSDate *)selectedDate;
                                                cell.valueLabel.text = [dateFormatter stringFromDate:date];
                                                [weakSelf saveVisibleObservationFieldValues];
                                            } cancelBlock:nil
                                               origin:self.view] showActionSheetPicker];
    }
}

#pragma mark - UITableView helpers

- (CGFloat)heightForSimpleProjectField:(ExploreProjectObservationFieldRealm *)field inTableView:(UITableView *)tableView font:(UIFont *)font {
    NSDictionary *attrs = @{
                            NSFontAttributeName: font,
                            };
    
    CGFloat usableWidth = tableView.bounds.size.width * .6;
    NSString *fieldName = field.observationField.name;
    CGRect fieldBoundingRect = [fieldName boundingRectWithSize:CGSizeMake(usableWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil];
    return fieldBoundingRect.size.height + 24;
}

- (CGFloat)heightForLongTextProjectField:(ExploreProjectObservationFieldRealm *)field inTableView:(UITableView *)tableView font:(UIFont *)font {
    NSDictionary *attrs = @{
                            NSFontAttributeName: font,
                            };

    CGFloat usableWidth = tableView.bounds.size.width - 14;
    NSString *fieldName = field.observationField.name;
    CGRect fieldBoundingRect = [fieldName boundingRectWithSize:CGSizeMake(usableWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil];
    // 44 for the value
    return fieldBoundingRect.size.height + 44;
    
    // return 66;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObservationFieldRealm *field = [project fields][indexPath.item];
    
    cell.textLabel.text = field.observationField.name;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.textLabel.numberOfLines = 2;
    cell.indentationLevel = 3;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)configureSimpleCell:(ObsFieldSimpleValueCell *)cell forObsField:(ExploreProjectObservationFieldRealm *)pof {
    cell.fieldLabel.text = pof.observationField.name;
    if (pof.required) {
        cell.fieldLabel.font = [UIFont boldSystemFontOfSize:cell.fieldLabel.font.pointSize];
    } else {
        cell.fieldLabel.font = [UIFont systemFontOfSize:cell.fieldLabel.font.pointSize];
    }
    
    /*
     TODO: realm
     move this into a helper function
     */
    ExploreObservationFieldValueRealm *obsFieldValue = nil;
    NSSet *ofvs = [self.observation observationFieldValues];
    for (ExploreObservationFieldValueRealm *fv in ofvs) {
        if (fv.fieldId == pof.observationField.fieldId) {
            obsFieldValue = fv;
            break;
        }
    }
    
    if (obsFieldValue) {
        if ([pof.observationField.dataType isEqualToString:@"taxon"]) {
            ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(obsFieldValue.value.integerValue)];
            if (etr) {
                cell.valueLabel.text = etr.commonName ?: etr.scientificName;
            } else {
                cell.valueLabel.text = (obsFieldValue.value.length == 0) ? @"unknown" : obsFieldValue.value;
            }

        } else {
            cell.valueLabel.text = obsFieldValue.value ?: pof.observationField.defaultValue;
        }
    } else {
        // show default
        NSString *defaultValue = pof.observationField.allowedValues.firstObject;
        cell.valueLabel.text = defaultValue;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureLongTextCell:(ObsFieldLongTextValueCell *)cell forObsField:(ExploreProjectObservationFieldRealm *)pof {
    cell.fieldLabel.text = pof.observationField.name;
    
    if (pof.required) {
        cell.fieldLabel.font = [UIFont boldSystemFontOfSize:cell.fieldLabel.font.pointSize];
    } else {
        cell.fieldLabel.font = [UIFont systemFontOfSize:cell.fieldLabel.font.pointSize];
    }

    cell.textField.delegate = self;
    
    ExploreObservationFieldValueRealm *obsFieldValue = nil;
    NSSet *ofvs = [self.observation observationFieldValues];
    for (ExploreObservationFieldValueRealm *fv in ofvs) {
        if (fv.fieldId == pof.observationField.fieldId) {
            obsFieldValue = fv;
            break;
        }
    }

    if (obsFieldValue) {
        cell.textField.text = obsFieldValue.value ?: pof.observationField.defaultValue;
    } else {
        cell.textField.text = nil;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
}


- (BOOL)projectIsSelected:(ExploreProjectRealm *)project {
    if (self.isReadOnly) {
        return NO;
    } else {
        return [self.observation.projectIds containsObject:@(project.projectId)];
    }
}

- (ExploreProjectRealm *)projectForSection:(NSInteger)section {
    if (self.isReadOnly) {
        return [self.readonlyObservationProjects objectAtIndex:section];
    } else {
        return [self.joinedInatProjects objectAtIndex:section];
    }
}

- (void)selectedChanged:(UISwitch *)switcher {
    NSInteger section = switcher.tag;
    
    NSMutableArray *indexPathsForSection = [NSMutableArray array];
    if (!switcher.isOn) {
        // we may have index paths to delete
        for (int i = 0; i < [self.tableView numberOfRowsInSection:section]; i++) {
            [indexPathsForSection addObject:[NSIndexPath indexPathForItem:i inSection:section]];
        }
    }
    
    ExploreProjectRealm *project = [self projectForSection:section];
    if (switcher.isOn) {
        // add observation to this project
        
    } else {
        // remove this observation from this project

    }
    
    /*
     TODO: realm
    Project *project = [self projectForSection:section];
    if (switcher.isOn) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = self.observation;
        po.project = project;
        
        NSMutableSet *existingOfvs = [NSMutableSet setWithSet:self.observation.observationFieldValues];
        for (ProjectObservationField *pof in po.project.sortedProjectObservationFields) {
            ObservationFieldValue *ofv = [[existingOfvs objectsPassingTest:^BOOL(ObservationFieldValue *obj, BOOL *stop) {
                return [obj.observationField isEqual:pof.observationField];
            }] anyObject];
            if (!ofv) {
                ofv = [ObservationFieldValue object];
                ofv.observation = self.observation;
                ofv.observationField = pof.observationField;
            }
        }
    } else {
        for (ProjectObservation *po in [self.observation.projectObservations copy]) {
            if ([po.project isEqual:project]) {
                for (ProjectObservationField *pof in po.project.sortedProjectObservationFields) {
                    ObservationFieldValue *ofv = [[self.observation.observationFieldValues objectsPassingTest:^BOOL(ObservationFieldValue *obj, BOOL *stop) {
                        return [obj.observationField isEqual:pof.observationField];
                    }] anyObject];
                    [ofv deleteEntity];
                }
                
                [self.observation removeProjectObservationsObject:po];
                [po deleteEntity];
            }
        }
    }
     */
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Objectstore Save Error: %@", error.localizedDescription]];
    }
    
    // reload the table view in a fraction of a second
    // allow the switcher animation to finish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (id)currentValueForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ObsFieldSimpleValueCell class]]) {
        return [[((ObsFieldSimpleValueCell *)cell) valueLabel] text];
    } else if ([cell isKindOfClass:[ObsFieldLongTextValueCell class]]) {
        return [[((ObsFieldLongTextValueCell *)cell) textField] text];
    } else {
        return nil;
    }
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    /*
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    if ([objectLoader.resourcePath rangeOfString:@"projects/user"].location != NSNotFound) {
        NSArray *rejects = [ProjectUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
        for (ProjectUser *pu in rejects) {
            [pu deleteEntity];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Objectstore Save Error: %@", error.localizedDescription]];
    }
    
    NSMutableArray *projects = [NSMutableArray array];
    [[ProjectUser all] enumerateObjectsUsingBlock:^(ProjectUser *pu, NSUInteger idx, BOOL *stop) {
        [projects addObject:pu.project];
    }];
    
    self.joinedProjects = [projects sortedArrayUsingDescriptors:[self joinedProjectSortDescriptors]];
    [self.tableView reloadData];
     */
}

@end
