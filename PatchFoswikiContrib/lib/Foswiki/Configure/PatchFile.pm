# See bottom of file for license and copyright information

package Foswiki::Configure::PatchFile;

use strict;
use warnings;
use File::Spec qw( splitdir splitpath catdir );
use Text::Patch;

=begin TML

---++ parsePatch($file ) -> %patch{filename} = diff
This routine will read in a patch file and parse it into separate patches.

=cut

sub parsePatch {
    my $file = shift;
    print STDERR "Processing $file\n";

    my %patches;
    my $error = '';

    $error .= "Not a file $file" unless ( -f $file );

    local $/ = "\n";
    open( my $fh, '<', $file ) || return "read of $file failed:  $!";
    my @contents = <$fh>;
    close $fh;

    $error .= "empty file $file" unless ( scalar @contents );

    if ($error) {
        $patches{error} = $error;
        return %patches;
    }

    my $foundPatch = 'summary';

    foreach my $line (@contents) {
        if ( $line =~ /^diff --git (.*?)\s/ ) {
            $foundPatch = _fixupFile($1);
        }
        $patches{$foundPatch} .= $line;
    }

    return %patches;
}

sub _fixupFile {
    my $patchFile = shift;

    my ( $volume, $directories, $file ) =
      File::Spec->splitpath( $patchFile, 0 );
    my @dirs = File::Spec->splitdir($directories);

    shift @dirs if $dirs[0] eq 'a';
    shift @dirs if $dirs[0] =~ /^core|Plugin$|Contrib$|Skin$|AddOn$/;

    # Don't include volume,  Caller will map to local name.
    $patchFile = File::Spec->catfile( @dirs, $file );

    print STDERR "Results $patchFile\n";

    return $patchFile;

}

=begin TML

---++ updateFile($file, patch )
This routine will update the filea and rewrite it into its original
location, preserving permissions.

=cut

sub updateFile {
    my $file  = shift;
    my $diff  = shift;
    my $write = shift;

    return 'Not a file' unless ( -f $file );

    local $/ = undef;
    open( my $fh, '<', $file ) || return "read of $file failed:  $!";
    my $src = <$fh>;
    close $fh;

    my $patched;

    eval { $patched = patch( $src, $diff, { STYLE => 'Unified' } ); };

    return "FAILED: $@" if $@;

    my $mode = ( stat($file) )[2];
    $file =~ /(.*)/;
    $file = $1;
    chmod( oct(600), "$file" );
    open( $fh, '>', $file ) || return "Rewrite $file failed:  $!";
    print $fh $patched;
    close $fh;
    $mode =~ /(.*)/;
    $mode = $1;
    chmod( $mode, "$file" );

    return '';
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2012 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2000-2006 TWiki Contributors. All Rights Reserved.
TWiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.