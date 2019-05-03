package WeBWorK::ContentGenerator::ProblemSets;
use base qw(WeBWorK);
use base qw(WeBWorK::ContentGenerator);

=head1 NAME

WeBWorK::ContentGenerator::ProblemSets - Display a list of built problem sets.

=cut

use strict;
use warnings;
#use CGI qw(-nosticky );
use WeBWorK::CGI;
use WeBWorK::Debug;
use WeBWorK::Utils qw(after readFile sortByName path_is_subdir is_restricted wwRound);
use WeBWorK::Localize;
# what do we consider a "recent" problem set?
use constant RECENT => 0; #60*60*24*14 # Two-Weeks in seconds  ## nope, not doing that -- Ryan
# the "default" data in the course_info.txt file
use constant DEFAULT_COURSE_INFO_TXT => "Put information about your course here.  Click the edit button above to add your own message.\n";


sub if_can {
  my ($self, $arg) = @_;

  if ($arg ne 'info') {
    return $self->can($arg) ? 1 : 0;
  } else {
    my $r = $self->r;
    my $ce = $r->ce;
    my $urlpath = $r->urlpath;
    my $authz = $r->authz;
    my $user = $r->param("user");

    # we only print the info box if the viewer has permission
    # to edit it or if its not the standard template box.
    
    my $course_info_path = $ce->{courseDirs}->{templates} . "/"
      . $ce->{courseFiles}->{course_info};
    my $text = DEFAULT_COURSE_INFO_TXT;

    if (-f $course_info_path) { #check that it's a plain  file
      $text = eval { readFile($course_info_path) };
    }
    return $authz->hasPermissions($user, "access_instructor_tools") ||
  $text ne DEFAULT_COURSE_INFO_TXT;
    
  }
}

sub info {
my ($self) = @_;
my $r = $self->r;
my $ce = $r->ce;
my $db = $r->db;
my $urlpath = $r->urlpath;
my $authz = $r->authz;

my $courseID = $urlpath->arg("courseID");
my $user = $r->param("user");

my $course_info = $ce->{courseFiles}->{course_info};

if (defined $course_info and $course_info) {
my $course_info_path = $ce->{courseDirs}->{templates} . "/$course_info";

# deal with instructor crap
my $editorURL;
if ($authz->hasPermissions($user, "access_instructor_tools")) {
if (defined $r->param("editMode") and $r->param("editMode") eq "temporaryFile") {
$course_info_path = $r->param("sourceFilePath");
$course_info_path = $ce->{courseDirs}{templates}.'/'.$course_info_path unless $course_info_path =~ m!^/!;
die "sourceFilePath is unsafe!" unless path_is_subdir($course_info_path, $ce->{courseDirs}->{templates});
$self->addmessage(CGI::div({class=>'temporaryFile'}, $r->maketext("Viewing temporary file: "), $course_info_path));
}

my $editorPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::Instructor::PGProblemEditor2",  $r, courseID => $courseID);
$editorURL = $self->systemLink($editorPage, params => { file_type => "course_info" });
}

if ($editorURL) {
print CGI::h2($r->maketext("Course Info"), CGI::a({href=>$editorURL, target=>"WW_Editor"}, $r->maketext("~[edit~]")));
} else {
print CGI::h2($r->maketext("Course Info"));
}
die "course info path is unsafe!" unless path_is_subdir($course_info_path, $ce->{courseDirs}->{templates}, 1); 
if (-f $course_info_path) { #check that it's a plain  file
my $text = eval { readFile($course_info_path) };
if ($@) {
print CGI::div({class=>"ResultsWithError"},
CGI::p("$@"),
);
} else {
print $text;
}
}

return "";
}
}



sub ryan_logout{
my ($self) = @_;
my $r = $self->r;
my $ce = $r->ce;
my $db = $r->db;
my $authz = $r->authz;
my $urlpath = $r->urlpath;
my $courseName = $urlpath->arg("courseID");
my $ryan_url = "https://wwdev2.math.msu.edu/webwork2/" . $courseName . "/";
	  
	  
print CGI::a({"aria-label"=>"Log Out", -style=>"padding: 7px 16px 6px 16px ;", "data-toggle"=>"tooltip", "data-placement"=>"bottom", -title=>"Log Out", -href=> $ryan_url . "/logout"}, 
	CGI::i({-class=>"material-icons", "aria-hidden"=>"true", "data-alt"=>"signout"}, "exit_to_app")
 );


return "";
}

sub ryan_userset{
my ($self) = @_;
my $r = $self->r;
my $ce = $r->ce;
my $db = $r->db;
my $authz = $r->authz;
my $urlpath = $r->urlpath;
my $courseName = $urlpath->arg("courseID");
my $ryan_url = "https://wwdev2.math.msu.edu/webwork2/" . $courseName . "/";
	  
	  
print CGI::a({"aria-label"=>"Log Out", -style=>"padding: 7px 16px 6px 16px ;", "data-toggle"=>"tooltip", "data-placement"=>"bottom", -title=>"User Settings", -href=> $ryan_url . "/logout"}, 
	CGI::i({-class=>"material-icons", "aria-hidden"=>"true", "data-alt"=>"signout"}, "account_circle")
 );


return "";
}




sub help {  # non-standard help, since the file path includes the course name
my $self = shift;
my $args = shift;
my $name = $args->{name};
$name = lc('course home') unless defined($name);
$name =~ s/\s/_/g;
$self->helpMacro($name);
}


sub templateName {
my $self = shift;
my $r = $self->r;
my $templateName = $r->param('templateName')//'system';
$self->{templateName}= $templateName;
$templateName;
}


sub initialize {



# get result and send to message
my ($self) = @_;
my $r = $self->r;
my $authz = $r->authz;
my $urlpath = $r->urlpath;

my $user              = $r->param("user");
my $effectiveUser      = $r->param("effectiveUser");
if ($authz->hasPermissions($user, "access_instructor_tools")) {
# get result and send to message
my $status_message = $r->param("status_message");
$self->addmessage(CGI::p("$status_message")) if $status_message;


}
}


sub body { 
my ($self) = @_;
my $r = $self->r;
my $ce = $r->ce;
my $db = $r->db;
my $authz = $r->authz;
my $urlpath = $r->urlpath;

my $user            = $r->param("user");
my $effectiveUser  = $r->param("effectiveUser");
my $sort            = $r->param("sort") || "status";

my $courseName      = $urlpath->arg("courseID");
my $my_course_id = uc $courseName;
$my_course_id =~ tr/'_'/' '/; 

my $char = ' ';
my $first_space = index($my_course_id, $char);
my $crse_code = '';
if ($first_space >0 ) {
	$crse_code = substr($my_course_id, 0, $first_space);
} else {
	$crse_code = "NO";
}

my $second_space = index($my_course_id, $char, $first_space) + $first_space + 1;

my $the_name = 'MSU ';  
if ($second_space > 0 && $first_space > 0) {
    $the_name .= substr($my_course_id, 0, $second_space); 
} else {
    $the_name .= $my_course_id; 
}

if (!($crse_code eq "MTH")) {
	$the_name = $my_course_id; 
} 	


print CGI::style({}, $r->maketext("#info-panel-right {display:none;}") );
print CGI::style({}, $r->maketext(".page-title { display:none; }") );
print CGI::h1({-style=>"text-align:center; border:2px solid #18453B; padding: 20px 0px; border-radius:5px; color: #18453B; font-size:40px; margin: 0px 0px;"}, $r->maketext($the_name) );

my $hardcopyPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::Hardcopy",  $r, courseID => $courseName);
my $actionURL = $self->systemLink($hardcopyPage, authen => 0); # no authen info for form action

# we have to get sets and versioned sets separately
# DBFIXME don't get ID lists, use WHERE clauses and iterators
my @setIDs = $db->listUserSets($effectiveUser);
my @userSetIDs = map {[$effectiveUser, $_]} @setIDs;

debug("Begin collecting merged sets");
my @sets = $db->getMergedSets( @userSetIDs );

debug("Begin fixing merged sets");

# Database fix (in case of undefined visible values)
# this may take some extra time the first time but should NEVER need to be run twice
# this is only necessary because some people keep holding to ww1.9 which did not have a visible field
# DBFIXME this should be in the database layer (along with other "fixes" of its ilk)
foreach my $set (@sets) {
	# make sure visible is set to 0 or 1
	if ( $set and $set->visible ne "0" and $set->visible ne "1") {
		my $globalSet = $db->getGlobalSet($set->set_id);
		$globalSet->visible("1");       # defaults to visible
		$db->putGlobalSet($globalSet);
		$set = $db->getMergedSet($effectiveUser, $set->set_id);
	} else {
		die "set $set not defined" unless $set;
	}
}

foreach my $set (@sets) {
	# make sure enable_reduced_scoring is set to 0 or 1
	if ( $set and $set->enable_reduced_scoring ne "0" and $set->enable_reduced_scoring ne "1") {
		my $globalSet = $db->getGlobalSet($set->set_id);
		$globalSet->enable_reduced_scoring("0");        # defaults to disabled
		$db->putGlobalSet($globalSet);
		$set = $db->getMergedSet($effectiveUser, $set->set_id);
	} else {
		die "set $set not defined" unless $set;
	}
}

# gateways/versioned sets require dealing with output data slightly 
# differently, so check for those here  
debug("Begin set-type check");
my $existVersions = 0;
my @gwSets = ();
my @nonGWsets = ();
my %gwSetNames = ();  # this is necessary because we get a setname
                      #    for all versions of g/w tests
foreach ( @sets ) { #where GW and nGW sets get filled
    if ( defined( $_->assignment_type() ) && $_->assignment_type() =~ /gateway/ ) {
		$existVersions = 1; 
		push( @gwSets, $_ ) if ( ! defined($gwSetNames{$_->set_id}) );
		$gwSetNames{$_->set_id} = 1;
    } else {
		push( @nonGWsets, $_ );
    }
}

# now get all user set versions that we need
my @vSets = ();
# we need the template sets below, so also make an indexed list of those
my %gwSetsBySetID = ();
foreach my $set ( @gwSets ) {
	$gwSetsBySetID{$set->set_id} = $set;
	my @setVer = $db->listSetVersions( $effectiveUser, $set->set_id );
	my @setVerIDs = map { [ $effectiveUser, $set->set_id, $_ ] } @setVer;
	push( @vSets, $db->getMergedSetVersions( @setVerIDs ) );
}

# set sort method
$sort = "name" unless $sort eq "status" or $sort eq "name";

#RYAN -- Not allowing fancy sorting of our tables for now. 
# now set the headers for the table
#my $nameHeader = $sort eq "name"
#? CGI::span($r->maketext("Name"))
#: CGI::a({href=>$self->systemLink($urlpath, params=>{sort=>"name"})}, $r->maketext("Name"));
#my $statusHeader = $sort eq "status"
#? CGI::span($r->maketext("Status"))
#: CGI::a({href=>$self->systemLink($urlpath, params=>{sort=>"status"})}, $r->maketext("Status"));

# print the start of the form
if ($authz->hasPermissions($user, "view_multiple_sets")) { 
    print CGI::start_form(-name=>"problem-sets-form", -id=>"problem-sets-form", -method=>"POST",-action=>$actionURL),
    $self->hidden_authen_fields;
}

		
debug("Begin sorting merged sets");

# before building final set lists, exclude proctored gateway sets 
#    for users without permission to view them
my $viewPr = $authz->hasPermissions( $user, "view_proctored_tests" );
@gwSets = grep {$_->assignment_type !~ /proctored/ || $viewPr} @gwSets;

if ( $sort eq 'name' ) {
    @nonGWsets = sortByName("set_id", @nonGWsets);
    @gwSets = sortByName("set_id", @gwSets);
} elsif ( $sort eq 'status' ) {
    @nonGWsets = sort byUrgency  @nonGWsets;
    @gwSets = sort byUrgency @gwSets;
}
# we sort set versions by name
@vSets = sortByName(["set_id", "version_id"], @vSets);

# put together a complete list of sorted sets to consider
#@sets = (@nonGWsets, @gwSets );

## breaking up sets into priority 0,1,2 

my %hash_of_set_arrays;

my @array_hws0 = ();
my @array_hws1 = ();
my @array_hws2 = ();
my @array_qzs0 = ();
my @array_qzs1 = ();
my @array_qzs2 = ();

$hash_of_set_arrays{"hws0"} = \@array_hws0 ;
$hash_of_set_arrays{"hws1"} = \@array_hws1 ;
$hash_of_set_arrays{"hws2"} = \@array_hws2 ;
$hash_of_set_arrays{"qzs0"} = \@array_qzs0 ;
$hash_of_set_arrays{"qzs1"} = \@array_qzs1 ;
$hash_of_set_arrays{"qzs2"} = \@array_qzs2 ;


foreach my $set ( @nonGWsets ) {
	push( @{ $hash_of_set_arrays{"hws" . myPriority($set)} }, $set);
}

foreach my $set ( @gwSets ) {
	push( @{ $hash_of_set_arrays{"qzs" . myPriority($set)} }, $set);
}


### then make the tables for each

if (scalar(@{$hash_of_set_arrays{"hws0"}}) > 0 ){

print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: #18453B; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px;"});
print CGI::a({"data-toggle"=>"collapse", -style=>"color:white !important;", href=>"#hws0"}, $r->maketext("Open Homework Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"hws0", -class=>"panel-collapse collapse in"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@{$hash_of_set_arrays{"hws0"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 

if (scalar(@{$hash_of_set_arrays{"qzs0"}}) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: #18453B; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px;"});
print CGI::a({"data-toggle"=>"collapse", -style=>"color:white !important;", href=>"#qzs0"}, $r->maketext("Open Timed Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"qzs0", -class=>"panel-collapse collapse in"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@{$hash_of_set_arrays{"qzs0"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 


if (scalar(@{$hash_of_set_arrays{"hws1"}}) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: SkyBlue; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px; color: #18453B;"});
print CGI::a({"data-toggle"=>"collapse", href=>"#hws1"}, $r->maketext("Future Homework Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"hws1", -class=>"panel-collapse collapse"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set ( @{$hash_of_set_arrays{"hws1"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 

if (scalar(@{$hash_of_set_arrays{"hws2"}}) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: SkyBlue; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px; color: #18453B;"});
print CGI::a({"data-toggle"=>"collapse", href=>"#hws2"}, $r->maketext("Past Due Homework Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"hws2", -class=>"panel-collapse collapse"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@{$hash_of_set_arrays{"hws2"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 


if (scalar(@{$hash_of_set_arrays{"qzs1"}}) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: Aquamarine; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px; color: #18453B;"});
print CGI::a({"data-toggle"=>"collapse", href=>"#qzs1"}, $r->maketext("Future Timed Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"qzs1", -class=>"panel-collapse collapse"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@{$hash_of_set_arrays{"qzs1"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 

if (scalar(@{$hash_of_set_arrays{"qzs2"}}) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: Aquamarine; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px; color: #18453B;"});
print CGI::a({"data-toggle"=>"collapse", href=>"#qzs2"}, $r->maketext("Past Due Timed Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"qzs2", -class=>"panel-collapse collapse"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@{$hash_of_set_arrays{"qzs2"}}) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db);
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 

if (scalar(@vSets) > 0 ){
print CGI::start_div({-class=>"panel-group"});
print CGI::start_div({-class=>"panel panel-default"});
print CGI::start_div({-class=>"panel-heading",  -style=>"background-color: MediumAquamarine; border-radius:4px !important;"});
print CGI::start_h4({-class=>"panel-title", -style=>"text-align:center; font-weight:bold; margin-bottom:0px; padding:10px 0px; color: #18453B;"});
print CGI::a({"data-toggle"=>"collapse", href=>"#vsets"}, $r->maketext("Previously Generated Versions of Timed Sets") );
print CGI::end_h4();
print CGI::end_div();
print CGI::start_div({-id=>"vsets", -class=>"panel-collapse collapse"});
print CGI::start_div({-class=>"panel-body"});

print CGI::start_table({-class=>"table table-striped", -style=>"margin-bottom:0px;"});
print CGI::Tr({},CGI::th({-scope=>"col"},$r->maketext("Name")), CGI::th({-scope=>"col"},$r->maketext("Status")));

	foreach my $set (@vSets) {
		die "set $set not defined" unless $set;
		if ($set->visible || $authz->hasPermissions($user, "view_hidden_sets")) {
			print $self->setListRow($set, $authz->hasPermissions($user, "view_multiple_sets"), $authz->hasPermissions($user, "view_unopened_sets"),$existVersions,$db,1, $gwSetsBySetID{$set->{set_id}}, "ethet" );  # 1 = gateway, versioned set
		}
	}

print CGI::end_table();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
print CGI::end_div();
} 

debug("End preparing merged sets");

# we do regular sets and the gateway set templates separately
# from the actual set-versions, to avoid managing a tricky test
# for a version number that may not exist

my $pl = ($authz->hasPermissions($user, "view_multiple_sets") ? "s" : "");
# print CGI::p(CGI::submit(-name=>"hardcopy", -label=>$r->maketext("Download Hardcopy for Selected [plural,_1,Set,Sets]",$pl)));

# UPDATE - ghe3
# Added reset button to form.

if ($authz->hasPermissions($user, "view_multiple_sets")) {
    print CGI::start_div({-class=>"problem_set_options"});
    #print CGI::start_p().WeBWorK::CGI_labeled_input(-type=>"reset", -id=>"clear", -input_attr=>{ -value=>$r->maketext("Clear")}).CGI::end_p();
    print CGI::start_p().WeBWorK::CGI_labeled_input(-type=>"submit", -id=>"hardcopy",-input_attr=>{-name=>"hardcopy", -value=>$r->maketext("Download PDF or TeX Hardcopy for Selected Sets")}).CGI::end_p();
    print CGI::end_div();
    print CGI::end_form();
}

## feedback form url
#my $feedbackPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::Feedback",  $r, courseID => $courseName);
#my $feedbackURL = $self->systemLink($feedbackPage, authen => 0); # no authen info for form action
#
##print feedback form
#print
#       CGI::start_form(-method=>"POST", -action=>$feedbackURL),"\n",
#       $self->hidden_authen_fields,"\n",
#       CGI::hidden("module",            __PACKAGE__),"\n",
#       CGI::hidden("set",                ''),"\n",
#       CGI::hidden("problem",            ''),"\n",
#       CGI::hidden("displayMode",        ''),"\n",
#       CGI::hidden("showOldAnswers",    ''),"\n",
#       CGI::hidden("showCorrectAnswers", ''),"\n",
#       CGI::hidden("showHints",          ''),"\n",
#       CGI::hidden("showSolutions",      ''),"\n",
#       CGI::p({-align=>"left"},
#       CGI::submit(-name=>"feedbackForm", -label=>"Email instructor")
#       ),
#       CGI::end_form(),"\n";

print $self->feedbackMacro(
module => __PACKAGE__,
set => "",
problem => "",
displayMode => "",
showOldAnswers => "",
showCorrectAnswers => "",
showHints => "",
showSolutions => "",
);

return "";
}

# UPDATE - ghe3
# this subroutine now combines the $control and $interactive elements, by using the $interactive element as the $control element's label.

sub setListRow {  #inputs a lot of stuff and outputs a row in the body table 
my ($self, $set, $multiSet, $preOpenSets, $existVersions, $db,
    $gwtype, $tmplSet) = @_;
my $r = $self->r;
my $ce = $r->ce;
my $authz = $r->authz;
my $user = $r->param("user");
my $effectiveUser = $r->param("effectiveUser") || $user;
my $urlpath = $r->urlpath;
my $globalSet = $db->getGlobalSet($set->set_id);
$gwtype = 0 if ( ! defined( $gwtype ) );
$tmplSet = $set if ( ! defined( $tmplSet ) );

##### Work to redo the title 
my $courseName      = $urlpath->arg("courseID");
my $my_course_id = uc $courseName;
$my_course_id =~ tr/'_'/' '/; 

my $char = ' ';
my $first_space = index($my_course_id, $char);
my $second_space = index($my_course_id, $char, $first_space) + $first_space + 1;

my $the_name = 'MSU ';  
if ($second_space > 0 && $first_space > 0) {
    $the_name .= substr($my_course_id, 0, $second_space); 
} else {
    $the_name .= $my_course_id; 
}

##### work to redo hw sets are displayed
my $name = $set->set_id;
my $display_name = $name;
$display_name =~ s/_/ /g;
my $display_name2 = $name;

$display_name2 = $name;
$display_name2 =~ tr/'_'/' '/;  # replaces underscore with space 
$display_name2 =~ tr/-/ /;  # replaces hyphen with space 

my $display_name3 = '';

if ($the_name eq "MSU MTH 133") {
	my $char5 = substr($display_name2, 4,1); 
	if ($char5 eq ' ') {
		$display_name3 .= substr($display_name2, 5); #removes first 5 chars in display 
	} else {
		$display_name3 .= $display_name2;
	}
} else {
	$display_name3 .= $display_name2;
}

######## work to compute score and such

####### HERE IS ALL THE STUFF TO CALCULATE THE SCORE 
$gwtype = 2 if ( defined( $set->assignment_type() ) && 
$set->assignment_type() =~ /gateway/ && ! $gwtype );


my $possible = 0;
my $score = 0;
my @problemRecords;
if ( defined($set->assignment_type()) && $set->assignment_type() =~ /gateway/ && $gwtype == 1 ) {
#if ( $gwtype == 0 || $gwtype == 1 ) {
		@problemRecords = $db->getAllProblemVersions($set->user_id(), $set->set_id(),$set->version_id());
		foreach my $pRec ( @problemRecords ) {
			my $pval = $pRec->value() ? $pRec->value() : 1; ## pval is the weight of the problem 
			if ( defined( $pRec ) && $score ne 'undef' ) { 
				$score += $pRec->status()*$pval || 0;  ## status is current % correct of that problem 
			} else {
				$score = 'undef';
			}
			$possible += $pval;
		}
		$score = wwRound(2,$score);
		$score = "$score/$possible";
	
} else {
	$score = "?/?";
}


##### Not my code

my @restricted = $ce->{options}{enableConditionalRelease} ?  
  is_restricted($db, $set, $effectiveUser) : ();
# The set shouldn't be shown if the LTI grade mode is set to homework and we dont
# have a source did to use to send back grades.  
my $LTIRestricted = defined($ce->{LTIGradeMode}) && $ce->{LTIGradeMode} eq 'homework'
  && !$set->lis_source_did;


my $urlname = ( $gwtype == 1 ) ? "$name,v" . $set->version_id : $name;
my $problemSetPage;

if ( ! defined( $set->assignment_type() ) || 
    $set->assignment_type() !~ /gateway/ ) {
    $problemSetPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::ProblemSet", $r, 
      courseID => $courseName, setID => $urlname);
} elsif( $set->assignment_type() !~ /proctored/ ) {

    $problemSetPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::GatewayQuiz", $r, 
      courseID => $courseName, setID => $urlname);
} else {

    $problemSetPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::ProctoredGatewayQuiz", $r, 
      courseID => $courseName, setID => $urlname);
}

my $interactiveURL = $self->systemLink($problemSetPage);

  # check to see if this is a template gateway assignment

  # and get problemRecords if we're dealing with a versioned set, so that
  #    we can test status and scores
  # FIXME: should we really have to get the merged 
  # problem_versions here?  it looks that way, because
  # otherwise we don't inherit things like the problem
  # value properly.
 
 ##### pulled code from here



my $interactive = CGI::a({class=>"btn btn-outline-primary btn-sm", href=>$interactiveURL}, "$display_name3");
my $control = "";
my $status = '';

my $setIsOpen = 0;      
if ( $gwtype ) { ### 0 -> regular hw, 1 -> a generated version, 2 -> a template (click to generate versions) 
  if ( $gwtype == 1 ) {	### its a generated version of a gateway assignment 
	my $startTime = $self->formatDateTime($set->version_creation_time()) || '';
    unless (ref($problemRecords[0]) ) {warn "Error: problem not defined in set $display_name"; return()}
    if ( $set->attempts_per_version() &&
		$problemRecords[0]->num_correct() + 
		$problemRecords[0]->num_incorrect() >= 
		$set->attempts_per_version()) 
	{
	  $status = $r->maketext("[_2]. completed. [_1]", $startTime, $score);
    } elsif ( time() > $set->due_date() + 
      $self->r->ce->{gatewayGracePeriod} ) {
      $status = $r->maketext("[_2]. over time, closed. [_1]", $startTime, $score);
    } else {
      $status = $self->set_due_msg($set,1);
    }

    $setIsOpen = 1;     # we let people go back to old tests    
    my $vnum = $set->version_id;      # reset the link to give the test number
    $interactive = CGI::a({class=>"btn btn-secondary btn-sm", href=>$interactiveURL}, $r->maketext("[_1] (v[_2])", $display_name3, $vnum));
  } else {
    my $t = time();
    if ( $t < $set->open_date() ) {
      $status = $r->maketext("will open on [_1]", $self->formatDateTime($set->open_date,undef,$ce->{studentDateDisplayFormat}));
      
      if (@restricted) {
		my $restriction = ($set->restricted_status)*100;
		$status .= restricted_progression_msg($r,1,$restriction,@restricted);
      }  
      if ( $preOpenSets ) {
		# reset the link
		$interactive = CGI::a({class=>"btn btn-info btn-sm", href=>$interactiveURL}, $r->maketext("[_1]", $display_name3));
      } else {	  
		$interactive = $r->maketext("[_1]", $display_name3);
      }
      $control = "";
      
    } elsif ( $t < $set->due_date() ) {
      
      $status = $self->set_due_msg($set,0);
      
      if (@restricted) {
		my $restriction = ($set->restricted_status)*100;
		$control = "" unless $preOpenSets;
		$interactive = $display_name unless $preOpenSets;
		$setIsOpen = 0;
		$status .= restricted_progression_msg($r,0,$restriction,@restricted);
      } elsif ($LTIRestricted) {
		$status .= CGI::br().$r->maketext("You must log into this set via your Learning Management System (e.g. Blackboard, Moodle, etc...).");  
		$control = "" unless $preOpenSets;
		$interactive = $display_name unless $preOpenSets;
		$setIsOpen = 0;
      } else {
		$setIsOpen = 1;
      }
      
      if ($setIsOpen ||  $preOpenSets ) {
		# reset the link
		my $my_id = '';
		$my_id = substr($display_name, 0, 4); 
		my $random_number = int(rand(10000));
		$my_id .= "-";
		$my_id .= $random_number;
		
		$interactive = CGI::a({class=>"btn btn-info btn-sm", "data-toggle"=>"modal", href=>"#m-".$my_id},
			  $r->maketext("[_1]", $display_name3));
		
		###MODAL
		print CGI::start_div({-class=>"modal hide fade", id=>"m-".$my_id, -tabindex=>"-1", -role=>"dialog"});
			print CGI::start_div({-class=>"modal-dialog", -role=>"document"});
				print CGI::start_div({-class=>"modal-content"});
					print CGI::start_div({-class=>"modal-header"});
						print CGI::h4({-class=>"modal-title", -style=>"margin:4px 0px"}, $r->maketext("Starting [_1]", $display_name3));
					print CGI::end_div();
					print CGI::start_div({-class=>"modal-body", -style=>"font-size:smaller"}, $r->maketext("You are about to start a timed assignment. <br><br> [_1] <br>Are you ready to start?", $globalSet->description()) );
					print CGI::div({}, $r->maketext("You are about to start a timed assignment. <br><br> [_1]", $globalSet->description()) );
							
					print CGI::start_div({-style=>"padding-right: 32px; display: inline-block; border-style: outset; border-color: red; background-color:LightCoral;"});
						print CGI::div({-style=>"padding: 12px 12px 0px 12px; font-weight: bold;"}, $r->maketext("RULES:"));
						print CGI::start_ul({-style=>"margin-top: 0px"});
							print CGI::li( $r->maketext("Do not navigate away from the browser page otherwise your answers may be lost."));
							print CGI::li( $r->maketext("Preview your answers often to save your work and make sure answers are typed correctly."));
							print CGI::li( $r->maketext("Submit your answers before time runs out otherwise your answers will be lost."));			
						print CGI::end_ul();
						print CGI::end_div();	
					print CGI::div({}, $r->maketext("<br>Are you ready to start?") );
	
					
					print CGI::end_div();					
					print CGI::start_div({-class=>"modal-footer"});
						print CGI::a({ -class=>"btn btn-secondary", "data-dismiss"=>"modal" }, $r->maketext("I'M NOT READY!") );
						print CGI::a({ -class=>"btn btn-primary", href=>$interactiveURL}, $r->maketext("START") );
					print CGI::end_div();
				print CGI::end_div();	
			print CGI::end_div();
		print CGI::end_div();		

		$control = "";

			
		
      } else {
		$control = "";
		$interactive = CGI::a({class=>"btn btn-info btn-sm"}, $r->maketext("[_1]", $display_name3));
      }
    } else {
      $status = $r->maketext("Closed");
	  
      if ( $authz->hasPermissions( $user, "record_answers_after_due_date" ) ) {
		$interactive = CGI::a({class=>"btn btn-danger btn-sm", href=>$interactiveURL}, $r->maketext("[_1]", $display_name3));
      } else {
		$interactive = CGI::a({class=>"btn btn-danger btn-sm", href=>$interactiveURL}, $r->maketext("[_1]", $display_name3));
      }
    }
  } 

### for not gateway assignments  aka gwtype =0
} elsif (time < $set->open_date) {
  $status = $r->maketext("will open on [_1]", $self->formatDateTime($set->open_date,undef,$ce->{studentDateDisplayFormat}));
  
  if (@restricted) {
    my $restriction = ($set->restricted_status)*100;
    $status .= restricted_progression_msg($r,1,$restriction,@restricted);
  }
  
  $control = "" unless $preOpenSets;
  $interactive = $display_name unless $preOpenSets;
  
} elsif (time < $set->due_date) {
  
  $status = $self->set_due_msg($set,0);
  
  if (@restricted) {
    my $restriction = ($set->restricted_status)*100;
    $control = "" unless $preOpenSets;
    $interactive = $display_name unless $preOpenSets;
    
    $status .= restricted_progression_msg($r,0,$restriction,@restricted);
    
    $setIsOpen = 0;
  } elsif ($LTIRestricted) {
    $status .= CGI::br().$r->maketext("You must log into this set via your Learning Management System (e.g. Blackboard, Moodle, etc...).");  
    $control = "" unless $preOpenSets;
    $interactive = $display_name unless $preOpenSets;
    $setIsOpen = 0;
  } else {
    $setIsOpen = 1;
  }
  
} elsif (time < $set->answer_date) {
  $status = $r->maketext("closed, answers available on [_1]", $self->formatDateTime($set->answer_date,undef,$ce->{studentDateDisplayFormat}) );
} else {
  $status = $r->maketext("closed, answers available" );
}

#### this is for instructors and those who can 'view' multiple sets 
if ($multiSet) {
  if ( $gwtype < 2 ) {
    $control = CGI::input({
  -type=>"checkbox",
  -id=>$name . ($gwtype ? ",v" . $set->version_id : ''), 
  -name=>"selected_sets",
  -value=>$name . ($gwtype ? ",v" . $set->version_id : '')
  });
    # make sure interactive is the label for control
    $interactive = CGI::label({"for"=>$name . ($gwtype ? ",v" . $set->version_id : '')},$interactive);
    
  } else {
    $control = '';
  }
} else {
  if ( $gwtype < 2 && after($set->open_date) && 
      (!@restricted || after($set->due_date))) {
    my $n = $name  . ($gwtype ? ",v" . $set->version_id : '');
    my $hardcopyPage = $urlpath->newFromModule("WeBWorK::ContentGenerator::Hardcopy", $r, courseID => $courseName, setID => $urlname);
    
    my $link = $self->systemLink($hardcopyPage,
params=>{selected_sets=>$n});
    $control = CGI::a({class=>"hardcopy-link", href=>$link},CGI::span({class=>"icon icon-download", title=>$r->maketext("Download [_1]",$set->set_id), 'data-alt'=>$r->maketext("Download [_1]",$set->set_id)}));
  } else {
    $control = '';
  }
}

my $visiblityStateClass = ($set->visible) ? "font-visible" : "font-hidden";
$status = CGI::span({class=>$visiblityStateClass}, $status) if $preOpenSets;
return CGI::Tr(CGI::td([$interactive,$status,]));

}

sub byname { $a->set_id cmp $b->set_id; }

sub byUrgency {
my $mytime = time;
my @a_parts = ($a->answer_date + RECENT <= $mytime) ?  (4, $a->open_date, $a->due_date, $a->set_id) 
: ($a->answer_date <= $mytime and $mytime < $a->answer_date + RECENT) ? (3, $a-> answer_date, $a-> due_date, $a->set_id)
: ($a->due_date <= $mytime and $mytime < $a->answer_date ) ? (2, $a->answer_date, $a->due_date, $a->set_id)
: ($mytime < $a->open_date) ? (1, $a->open_date, $a->due_date, $a->set_id) 
: (0, $a->due_date, $a->open_date, $a->set_id);
my @b_parts = ($b->answer_date + RECENT <= $mytime) ?  (4, $b->open_date, $b->due_date, $b->set_id) 
: ($b->answer_date <= $mytime and $mytime < $b->answer_date + RECENT) ? (3, $b-> answer_date, $b-> due_date, $b->set_id)
: ($b->due_date <= $mytime and $mytime < $b->answer_date ) ? (2, $b->answer_date, $b->due_date, $b->set_id)
: ($mytime < $b->open_date) ? (1, $b->open_date, $b->due_date, $b->set_id) 
: (0, $b->due_date, $b->open_date, $b->set_id);
my $returnIt=0;
while (scalar(@a_parts) > 1) {
if ($returnIt = ( (shift @a_parts) <=> (shift @b_parts) ) ) {
return($returnIt);
}
}
return (  $a_parts[0] cmp  $b_parts[0] );
}

sub myPriority { #2 after due date, #1 before open date, #0 if currently open 
my $mytime = time;
my ($my_set) = @_; 
my $set_ddate = $my_set->due_date;
my $set_odate = $my_set->open_date;

if ($set_ddate <= $mytime) {return "2";}
elsif ($mytime < $set_odate ) {return "1";}
else {return "0";}

}


sub check_sets {
my ($self,$db,$sets_string) = @_;
my @proposed_sets = split(/\s*,\s*/,$sets_string);
foreach(@proposed_sets) {
  return 0 unless $db->existsGlobalSet($_);
  return 1;
}
}

sub set_due_msg {
  my $self = shift;
  my $r = $self->r;
  my $ce = $r->ce;
  my $set = shift;
  my $gwversion = shift;
  my $status = ''; 

  my $enable_reduced_scoring =  $ce->{pg}{ansEvalDefaults}{enableReducedScoring} && $set->enable_reduced_scoring && $set->reduced_scoring_date &&$set->reduced_scoring_date < $set->due_date;
  my $reduced_scoring_date = $set->reduced_scoring_date;
  my $beginReducedScoringPeriod =  $self->formatDateTime($reduced_scoring_date,undef,$ce->{studentDateDisplayFormat});

  my $t = time;

  if ($enable_reduced_scoring &&
      $t < $reduced_scoring_date) {
    
    $status .= $r->maketext("open, due [_1]", $beginReducedScoringPeriod);
    $status .= CGI::div({-class=>"ResultsAlert", -style=>"font-weight:normal !important;"}, $r->maketext("some reduced credit can be earned after the due date"));

	} else {
    if ($gwversion) {
      $status = $r->maketext("open, complete by [_1]",  $self->formatDateTime($set->due_date(),undef,$ce->{studentDateDisplayFormat}));
    } else {
      $status = $r->maketext("open, due [_1]",  $self->formatDateTime($set->due_date(),undef,$ce->{studentDateDisplayFormat}));  
    }

    if ($enable_reduced_scoring && $reduced_scoring_date &&
$t > $reduced_scoring_date) {
      $status .= CGI::div({-class=>"ResultsAlert"}, $r->maketext("some reduced credit can currently be earned!"));
    }
  }

  return $status;
}  
  

sub restricted_progression_msg {
  my $r = shift;
  my $open = shift;
  my $restriction = shift;
  my @restricted = @_;
  my $status = ' ';

  if ($open) {
    $status .= $r->maketext("if you score at least [_1]% on", sprintf("%.0f",$restriction));
  } else {
    $status .= $r->maketext("but to access it you must score at least [_1]% on", sprintf("%.0f",$restriction));
  }
  
  $status .= ' ';
  
  if (scalar(@restricted) == 1) {
    $status .= $r->maketext("set [_1].", @restricted);
  } else {
    $status .= $r->maketext("sets");
    foreach(0..$#restricted) {
      $status .= " $restricted[$_], " if $_ != $#restricted;
      $status .= " ".$r->maketext("and")." ".$restricted[$_].'.' if $_ == $#restricted;
    }
  }

  return $status;
}
  
  

1;
