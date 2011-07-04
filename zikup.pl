#!/usr/bin/env perl

# zikup.pl
# Incremental Recursive Archiving Backup with Perl, currently using 7z.


# Copyright (c) 2010, Daniel Åkesson - danielakesson at gmail dot com
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the <organization> nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


use warnings;
use strict;

my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();

$month = sprintf("%02d", $month + 1);
$dayOfMonth = sprintf("%02d", $dayOfMonth);
$dayOfMonth = sprintf("%02d", $dayOfMonth);
$hour = sprintf("%02d", $hour);
$minute = sprintf("%02d", $minute);
$second = sprintf("%02d", $second);


print("zikup v0.1\n");
print("----------\n");


if ($#ARGV < 4) {
  print("Usage: zikup <backup path> <projectname> <total amount of archives> <password> <files_or_paths...>\n\n");
  exit(0);
}
else {
  if ($ARGV[2] =~ /\D+/) {
    print("Third argument, \"" . $ARGV[2] . "\" is supposed to be a number.\n");
    exit(0);
  }
}


my $to_backup_global = "";
for (my $i = 4; $i <= $#ARGV; ++$i) {
  if (!-e $ARGV[$i]) {
    print("\"" . $ARGV[$i] . "\" doesn't exist.\n");
    exit(1);
  }
  $to_backup_global .= $ARGV[$i] . " ";
}

my $global_backup_location = $ARGV[0];
my $projects = {$ARGV[1] => {'backup_location' => $global_backup_location, 'to_backup' => $to_backup_global}};

my $password = $ARGV[3];

my $zip_tool_to_use = "7-zip";
#my $zip_tools = { '7-zip' => "7z a -mx=9 !zipfile! !to_backup!"};
my $zip_tools = { '7-zip' => "7z a -p$password -mx=9 -mhe=on !zipfile! !to_backup!"};


foreach my $project (keys(%$projects)) {

  my $backup_location = $projects->{$project}->{'backup_location'} || $global_backup_location;

  # Get all possible backups.
  my @files = sort(glob("$backup_location/*.7z"));
  # Filter out only backups for the project.
  @files = map($_ =~ /\/$project\_\d{4}-\d{2}-\d{2}\_\d{2}\.\d{2}.\d{2}\.7z/g, @files);

  if (@files) {
    print "Found backup files:\n";
    foreach my $file (@files) {
      print $file . "\n";
    }
  }

  # This is done first, to make it possible to backup on a full hdd. This way, it should be freed up for another
  # backup. And thus, we will have a backup with latest data in it. Otherwise it will not be able to create the
  # backup file. Also, a backup is only removed when a certain amount is reached, so there should always be
  # atleast one backup... (if the value here is set to atleast 2)...
  # Obviously, this is a problem if data is filling the hdd after the backup is deleted!
  if (scalar(@files) >= $ARGV[2]) {
    print "Deleting oldest: " . $backup_location . "/" . $files[0] . "...";
    unlink($global_backup_location . "/" . $files[0]) or die("$!\n");
    print " done.\n";
  }

  my $new_backup = $project . "_" . ($yearOffset+1900) . "-$month-" . $dayOfMonth . "_$hour.$minute.$second.7z";
  $new_backup = $backup_location . "/$new_backup";
  $new_backup =~ s/\/\//\//g;

  #print "New Backup file: $new_backup\n";


  my $to_backup = "";
  if (ref($projects->{$project}->{'to_backup'}) eq 'ARRAY') {
    $to_backup = join(" ", @{$projects->{$project}->{'to_backup'}});
  }
  else {
    $to_backup = $projects->{$project}->{'to_backup'};
  }

  $to_backup =~ s/\/\//\//g;
  #foreach my $to_backup (@{$projects->{$_}->{'to_backup'}}) {
  #print $project . ": $to_backup\n";
  #}

  my $zip = $zip_tools->{$zip_tool_to_use};
  $zip =~ s/!zipfile!/$new_backup/g;
  $zip =~ s/!to_backup!/$to_backup/g;

  #print $project . ": $to_backup\n";
  print $project . ": $zip\n";
  my $error = system($zip);
  if (!$error) {
  }
}


