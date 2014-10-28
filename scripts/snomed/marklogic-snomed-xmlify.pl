#!/usr/local/bin/perl -w
#
#   Copyright (c) 2014 International Health Terminology Standards Development Organisation
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OR ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License
#
#   Version 0.1, Date: 2014-07-21, Author: Ryan J. Dew
#   Derived from: tls2_StatedRelationshipsToOwlKRSS_US1000124_20140301, Version 6.0, Date: 2013-12-23, Author: Kent Spackman
# Run the script as "perl <scriptfilename> <arg0>" where
#  <scriptfilename> is the name of the file containing this script
#  <arg0> is the directory containing the RF2 Snapshot subdirectories.
#           If the current directory is RF2/Snapshot, then just use dot (".") to designate the current directory, as in the following example:
# ***  EXAMPLE COMMAND FOR RUNNING THE SCRIPT: >perl marklogic-xmlify.pl .
#
#
# Alternatively you can separately supply arguments for all the file names (with their directories if necessary) :
# Run the script as "perl <scriptfilename> <arg0> <arg1> <arg2> <arg3> <arg4> <arg5>" where
#  <scriptfilename> is the name of the file containing this script
#  <arg0> is the name of the file containing the SNOMED CT RF2 Concepts Table snapshot e.g. sct2_Concept_Snapshot_INT_20140131.txt
#  <arg1> is the name of the file containing the SNOMED CT RF2 Descriptions Table snapshot e.g. sct2_Description_Snapshot_INT_20140131.txt
#  <arg2> is the name of the file containing the SNOMED CT RF2 Stated Relationships Table snapshot, e.g. sct2_StatedRelationship_Snapshot_INT_20140131.txt
#  <arg3> is the name of the file containing the SNOMED CT RF2 Text Definitions Table snapshot, e.g. sct2_TextDefinition_Snapshot-en_INT_20140131.txt
#  <arg4> is the name of the file containing the SNOMED CT RF2 Language Refset snapshot, e.g. der2_cRefset_LanguageSnapshot-en_INT_20140131.txt
#  <arg5> is the name of the output file, which is your choice but could be something like res_StatedOWLF_Core_INT_20140131.owl
#
# The script relies on the hierarchy under 410662002 "Concept model attribute" to specify the role hierarchies.

# The output consists of:
# 1) A set XML files representing concept definitions for use with MarkLogic.

use English;
use feature qw(say);

my %fsn;
my %desc;
my %textDefs;
my %prefTerm;
my %acceptability;
my %primitive;
my %parents;
my %children;
my %rels;
my %roles;
my %rightids;
my %nevergrouped;

# -------------------------------------------------------------------------------------------
# SPECIAL DECLARATIONS for attribute hierarchy, IS A relationships, non-grouping, and right identities
# CAUTION: The values for these parameters depend on the particular release of SNOMED CT.
# Do not assume they remain stable across different releases.
# **************************************************************
# These values are valid for:  20140131, release format 2 (RF2).
# **************************************************************
# -------------------------------------------------------------------------------------------

$conceptModelAttID = "410662002"
  ; # the SCTID of the concept at the top of the concept model attribute hierarchy
$isaID = "116680003";    # the SCTID of the IS A relationship concept
$nevergrouped{"123005000"} = "T";    # part-of is never grouped
$nevergrouped{"272741003"} = "T";    # laterality is never grouped
$nevergrouped{"127489000"} = "T";    # has-active-ingredient is never grouped
$nevergrouped{"411116001"} = "T";    # has-dose-form is never grouped
$rightid{"363701004"}      =  "127489000";    # direct-substance o has-active-ingredient -> direct-substance

$coreModuleId = "900000000000207008";
# $metadataModuleId = "900000000000012004"; # when reading in concepts, can exclude metadata module concepts
$conceptDefinedId = "900000000000073002";
$FSNId = "900000000000003001";
$DescId =  "900000000000013009";
# Setting of terms to preferred vs synonym vs not acceptable is according to Language Refset ID
$LanguageRefsetId = "900000000000509007"; # US English
# $LanguageRefsetId = "900000000000508004"; # GB English

$PreferredTermId = "900000000000548007";
$AcceptableTermId = "900000000000549004";
$ctsWordOptions = "<cts:option>whitespace-insensitive</cts:option>";

$rgidonly = "609096000";
$rgsctid = "id/$rgidonly"; # role group attribute SCTID

# -- Collect the needed files in a separate list #
my @dataFiles;
my $outputFile;
my $dlformat;
# -------------------------------------------------------------------------------------------
print "# Number of arguments: " . scalar (@ARGV) . "\n";
if ( @ARGV == 1)
{
    print "[INFO] One argument passed. Assuming it is Snapshot folder location \n";

  # Use Snapshot folder location to get Terminology files in path	#
  my $dirname = $ARGV[0] . "/Terminology";
  opendir my($dh), $dirname or die "Couldn't open dir '$dirname': $!";

  my @files = readdir $dh;
  closedir $dh;

   print "[INFO] Processing files in location : " . $dirname . "\n";
  foreach my $file (@files)
  {
     if ($file =~ /_Concept_Snapshot_/) {
       $dataFiles[0] = $dirname ."/". $file;
       say "[INFO] Using file : " . $file . " for Concepts";
     }elsif ($file =~ /_Description_Snapshot/) {
       $dataFiles[1] = $dirname ."/". $file;
       say "[INFO] Using file : " . $file . " for Descriptions";
     }elsif ($file =~ /_StatedRelationship_Snapshot_/) {
       $dataFiles[2] = $dirname ."/". $file;
       say "[INFO] Using file : " . $file . " for Stated Relationships";
     }elsif ($file =~ /_TextDefinition_Snapshot/) {
       $dataFiles[3] = $dirname ."/". $file;
       say "[INFO] Using file : " . $file . " for Text Definitions";
     }else{
# 			print "[INFO] Ignoring file : " . $file . "\n";
     }
   }

   # now get the Language Refset filename
   my $refsetdirname = $ARGV[0] . "/Refset/Language";
   opendir $dh, $refsetdirname or die "Couldn't open dir '$refsetdirname': $!";
   @files = readdir $dh;
   closedir $dh;
   print "[INFO] Processing files in location : " . $refsetdirname . "\n";
   foreach my $file (@files)
   {
      if ($file =~ /_cRefset_LanguageSnapshot/) {
         $dataFiles[4] = $refsetdirname . "/" . $file;
         say "[INFO] Using file : " . $file . " for Language Refset";
      } else {
# 	      say "[INFO] Ignoring file : " . $file;
      }
   }

   # Assign data file names by passing array values to sub routine assign_data_files
   &assigndatafiles($dataFiles[0], $dataFiles[1], $dataFiles[2], $dataFiles[3], $dataFiles[4]);
}
elsif(@ARGV == 6)
{
    # Assign data file names by passing array values to sub routine assign_data_files
   &assigndatafiles($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);

   # Assign output file
   $outputFile = $ARGV[5];
}
else
{
  die "[WARN] You must pass 1 or 6 argument(s)!
  \n[WARN] If you are passing 1 argument, it is the data location path.
  \n[WARN] If you are passing 6 arguments, please read the documentation in the script";
}

# Sub routine for assigning data files #
sub assigndatafiles
{
  $conceptsFileName     = $_[0];
  $descriptionsFileName = $_[1];
  $statedRelsFileName   = $_[2];
  $textDefFileName      = $_[3];
  $languageRefsetFileName = $_[4];
}

#-------------------------------------------------------------------------------
# File 1: The RF2 concepts table snapshot.
# Fields are: id[0], effectiveTime[1], active[2], moduleId[3], definitionStatusId[4]
#-------------------------------------------------------------------------------

open( CONCEPTS, $conceptsFileName ) || die "can't open $conceptsFileName \n";

# read input rows
while (<CONCEPTS>) {
  s/\015//g;
  s/\012//g;    # remove CR and LF characters
  @values = split( '\t', $_ );    # input file is tab delimited
     # Filter out the header line, blank lines, and all inactive and metadata concepts
  if ( $values[0] && ( $values[2] eq "1") && ( $values[3] eq $coreModuleId ) )
  {
      my $primdefFlag = "1";
      if ($values[4] eq $conceptDefinedId) { $primdefFlag = "0"; }
    $primitive{ $values[0] } = $primdefFlag;
  }
}
close(CONCEPTS);

#-------------------------------------------------------------------------------
# File 5: The Language Refset. - Read it in before reading in the descriptions table
# Fields are: id[0], effectiveTime[1], active[2], moduleId[3], refsetId[4], descriptionID[5], acceptabilityId[6]
#-------------------------------------------------------------------------------

open( LANG, $languageRefsetFileName ) || die "can't open $languageRefsetFileName \n";

# read input rows
while (<LANG>) {
  s/\015//g;
  s/\012//g;    # remove CR and LF characters
  @values = split( '\t', $_ );    # input file is tab delimited
     # Filter out the header/blank/inactive lines, and keep only core module rows for refset $LanguageRefsetId
  if ( $values[0] && ( $values[2] eq "1") && ( $values[3] eq $coreModuleId ) && ($values[4] eq $LanguageRefsetId ) )
  {
        $acceptability{ $values[5] } = $values[6];
  }
}
close(LANG);

#-------------------------------------------------------------------------------
# File 2: The RF2 descriptions table snapshot.
# Fields are: id[0], effectiveTime[1], active[2], moduleId[3], conceptId[4],
# languageCode[5], typeId[6], term[7], caseSignificanceId[8]
#-------------------------------------------------------------------------------

open( DESCRIPTIONS, $descriptionsFileName ) || die "can't open $descriptionsFileName \n";

# read input rows
while (<DESCRIPTIONS>) {
  s/\015//g;
  s/\012//g;    # remove CR and LF characters
  @values = split( '\t', $_ );    # input file is tab delimited
     # Filter out the header line, blank lines
  if ( $values[0] && $values[2] eq "1") { # not a header line or blank line, and status is active
     if ($values[6] eq $FSNId ) { # this is an FSN type of description
       $fsn{ $values[4] } = &xmlify( $values[7] ); # xmlify changes & to &amp; < to &lt; > to &gt;
       }
    elsif ($values[6] eq $DescId ) { # this is a non-FSN ordinary description
             if ( $acceptability{ $values[0] }) { # if the language refset indicates an acceptability for this description
                 if ($acceptability{ $values[0] } eq $PreferredTermId ) { # if is the preferred term
                     $prefTerm { $values[4] } = &xmlify($values[7]);
             } elsif ( $acceptability{ $values[0] } eq $AcceptableTermId ) { # if it is acceptable
                 if ($desc{ $values[4] }) {
                         push @{ $desc{ $values[4] } },  &xmlify($values[7]); # push onto list of synonyms for this concept
                     } else {
                         $desc{ $values[4] } = [ &xmlify($values[7]) ];
                     }
             }
          }
       }
  }
}
close(DESCRIPTIONS);


#-------------------------------------------------------------------------------
# File 4: The Text Definitions File
# Fields are: id[0], effectiveTime[1], active[2], moduleId[3], conceptId[4], languageCode[5], typeId[6], term[7], caseSignificanceId[8]
#-------------------------------------------------------------------------------

open( TEXTDEF, $textDefFileName ) || die "can't open $textDefFileName \n";

# read input rows
while (<TEXTDEF>) {
  s/\015//g;
  s/\012//g;    # remove CR and LF characters
  @values = split( '\t', $_ );    # input file is tab delimited
     # Filter out the header/blank/inactive lines, and keep only core module rows
  if ( $values[0] && ( $values[2] eq "1") && ( $values[3] eq $coreModuleId )  )
  {
        $textDefs{ $values[4] } = &xmlify($values[7]);
  }
}
close(TEXTDEF);


foreach $c1 ( sort keys %primitive ) {
  open( OUTF, ">output/".$c1.".xml" ) or die "can't open output file: output/".$c1.".xml";
  say OUTF "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  &printconceptdefxml($c1);
}

# =====================================================
# end of main program
# =====================================================

# =====================================================
# Subroutines
# =====================================================

sub xmlify {
  my ($fsnstring) = @_;
  $fsnstring =~ s/&/&amp;/g;
  $fsnstring =~ s/</&lt;/g;
  $fsnstring =~ s/>/&gt;/g;
  return $fsnstring;
}

sub printwordqueryxml {    # print object properties of OWL RDF/XML syntax
  my ($text) = @_;
  $wordOpt = $ctsWordOptions;
  if ($text eq uc($text) || $text =~ m/\b[a-z]+[A-Z]/) {
    $wordOpt = $wordOpt."<cts:option>case-sensitive</cts:option>";
  } else {
    $wordOpt = $wordOpt."<cts:option>case-insensitive</cts:option>";
  }
  if (length($text) > 3) {
    $wordOpt = $wordOpt."<cts:option>stemmed</cts:option>";
  } else {
    $wordOpt = $wordOpt."<cts:option>unstemmed</cts:option>";
  }
  say OUTF "    <cts:word-query>";
  say OUTF "     <cts:text xml:lang=\"en\">", $text, "</cts:text>".$wordOpt;
  say OUTF "    </cts:word-query>";
}

# --------------------------------------------------------------------------

sub printconceptdefxml {
  my ($c1) = @_;
  if ( $parentpointer = $parents{$c1} ) {
    $nparents = @$parentpointer;
  }
  else { $nparents = 0; }
  if ( $rels{$c1} ) { $nrels = 1; }
  else { $nrels = 0; }
  $nelements = $nparents + $nrels;
  my @types = ();
  while ($fsn{$c1} =~ /\(( (?: [^\(\)]* | (?0) )* )\)/xg) {
    $val = $1;
    $val =~ s/"/&quot;/g;
    push(@types,$val);
  };
  say OUTF "<concept xmlns=\"http://marklogic.com/demo/ontology\" xmlns:cts=\"http://marklogic.com/cts\">";
  say OUTF "   <source>SNOMED</source>";
  say OUTF "   <label>",$fsn{$c1},"</label>";
  say OUTF "   <notation subject=\"patient\" code-schema=\"SNOMED\" code=\"",$c1,"\" type=\"",$types[0],"\" iri=\"http://snomed.info/id/",$c1,"\"/>";
  if ($textDefs{$c1}) { say OUTF "    <description xml:lang=\"en\">", $textDefs{$c1}, "</description>"; }
  say OUTF "  <reverse-query>";
  &printwordqueryxml($fsn{$c1});
  if ($prefTerm{$c1}) {
    &printwordqueryxml($prefTerm{$c1});
  }
  if ($desc{$c1}) {
     foreach $descrip ( @{ $desc{$c1} }) {
        &printwordqueryxml($descrip);
     }
  }
  say OUTF "  </reverse-query>";
  say OUTF "</concept>";
}
