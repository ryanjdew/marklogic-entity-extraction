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
#   Version 0.1, Date: 2013-12-23, Author: Kent Spackman
#   Derived from: tls2_StatedRelationshipsToOwlKRSS_US1000124_20140301, Version 6.0, Date: 2013-12-23, Author: Kent Spackman
# Run the script as "perl <scriptfilename> <arg0>" where
#  <scriptfilename> is the name of the file containing this script
#  <arg0> is the directory containing the RF2 Snapshot subdirectories.
#           If the current directory is RF2/Snapshot, then just use dot (".") to designate the current directory, as in the following example:
# ***  EXAMPLE COMMAND FOR RUNNING THE SCRIPT: >perl marklogic-xmlify.pl .
#
#
# The output consists of:
# 1) A set XML files representing RXNORM definitions for use with MarkLogic.

use English;
use feature qw(say);

my %concepts;
my %synonyms;
my %normalized;
my %spls;
my %splVersions;
my %textDefs;
my %conceptsFileName;
my %splMappingFileName;

$ctsWordOptions = "<cts:option>whitespace-insensitive</cts:option>";

# -- Collect the needed files in a separate list #
my @dataFiles;
my $outputFile;
# -------------------------------------------------------------------------------------------
print "# Number of arguments: " . scalar (@ARGV) . "\n";
if ( @ARGV == 1 || @ARGV == 2)
{
    print "[INFO] One argument passed. Assuming it is Snapshot folder location \n";

  # Use Snapshot folder location to get Terminology files in path	#
  my $dirname = $ARGV[0] . "/rrf";
  opendir my($dh), $dirname or die "Couldn't open dir '$dirname': $!";

  my @files = readdir $dh;
  closedir $dh;

   print "[INFO] Processing files in location : " . $dirname . "\n";
  foreach my $file (@files)
  {
     if ($file =~ /RXNCONSO/) {
       $dataFiles[0] = $dirname ."/". $file;
       say "[INFO] Using file : " . $file . " for Concepts";
     }
   }

   # Assign data file names by passing array values to sub routine assign_data_files
   &assigndatafiles($dataFiles[0],$ARGV[1]);
}

else
{
  die "[WARN] You must pass 1 argument!
  \n[WARN] If you are passing 1 argument, it is the data location path.";
}

# Sub routine for assigning data files #
sub assigndatafiles
{
  $conceptsFileName   = $_[0];
  $splMappingFileName = $_[1];
}

#-------------------------------------------------------------------------------
# File 1: The RF2 concepts table snapshot.
# Fields are: rxcui[0], lang[1], sourceVocabulary[11], termType[12], value[14]
#-------------------------------------------------------------------------------

open( CONCEPTS, $conceptsFileName ) || die "can't open $conceptsFileName \n";

# read input rows
while (<CONCEPTS>) {
  s/\015//g;
  s/\012//g;    # remove CR and LF characters
  @values = split( '\|', $_ );    # input file is pipe delimited
  # Filter out the header line, and blank lines
  if ($values[0])
  {
    $concepts{$values[0]} = '1';
  }
  if ($values[11] eq "RXNORM") {
    if ($normalized{ $values[0] }) {
      push @{ $normalized{ $values[0] } },  &xmlify($values[14]);
    } else {
      $normalized{$values[0]} = [&xmlify($values[14])];
    }
  } else {
    if ($synonyms{ $values[0] }) {
      push @{ $synonyms{ $values[0] } },  &xmlify($values[14]);
    } else {
      $synonyms{$values[0]} = [&xmlify($values[14])];
    }
  }
}
close(CONCEPTS);

#-------------------------------------------------------------------------------
# File 1: The SPL mapping file
# Fields are: splSetId[0], splVersion[1] rxcui[2]
#-------------------------------------------------------------------------------
if ($splMappingFileName) {
  print "[INFO] Using file : " . $splMappingFileName . " for SPL mapping\n";
  open( SPLS, $splMappingFileName ) || die "can't open $splMappingFileName \n";

  # read input rows
  while (<SPLS>) {
    s/\015//g;
    s/\012//g;    # remove CR and LF characters
    @values = split( '\|', $_ );    # input file is pipe delimited
    # Filter out the header line, and blank lines
    if ($values[0]) {
      if (!$splVersions{$values[2]} || $values[1] > $splVersions{$values[2]}) {
        $spls{$values[2]} = $values[0];
        $splVersions{$values[2]} = $values[1];
      }
    }
  }
  close(SPLS);
}

foreach $c1 ( sort keys %concepts ) {
  if ($normalized{$c1}[0] || $synonyms{$c1}[0]) {
    open( OUTF, ">output/".$c1.".xml" ) or die "can't open output file: output/".$c1.".xml";
    say OUTF "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    &printconceptdefxml($c1);
  } else {
    print "[INFO] No text for: " . $c1 . "\n";
  }
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

# --------------------------------------------------------------------------
# routines for handling role (attribute) definitions
# --------------------------------------------------------------------------

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
  say OUTF "<concept xmlns=\"http://marklogic.com/demo/ontology\" xmlns:cts=\"http://marklogic.com/cts\">";
  say OUTF "   <source>RXNORM</source>";
  if ($normalized{$c1}[0]) {
    say OUTF "   <label>",$normalized{$c1}[0],"</label>";
  } elsif ($synonyms{$c1}[0]) {
    say OUTF "   <label>",$synonyms{$c1}[0],"</label>";
  }
  say OUTF "   <notation subject=\"patient\" type=\"medication\" code-schema=\"RXNORM\" code=\"",$c1,"\" iri=\"http://purl.bioontology.org/ontology/RXNORM/",$c1,"\"";
  if ($spls{$c1}) {
    say OUTF " spl=\"",$spls{$c1},"\""
  }
  say OUTF "/>";
  if ($textDefs{$c1}) { say OUTF "    <description xml:lang=\"en\">", $textDefs{$c1}, "</description>"; }
  say OUTF "  <reverse-query>";
  if ($synonyms{$c1}) {
    foreach $descrip ( @{ $synonyms{$c1} }) {
      &printwordqueryxml($descrip);
    }
  }
  if ($normalized{$c1}) {
    foreach $descrip ( @{ $normalized{$c1} }) {
      &printwordqueryxml($descrip);
    }
  }
  say OUTF "  </reverse-query>";
  say OUTF "</concept>";
}
