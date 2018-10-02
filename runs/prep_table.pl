#!/usr/bin/env perl
#-*-Perl-*-
#
open (PARAMS, "<prep_table.txt");
while (<PARAMS>) {
   chop;
   @line = split;
   $fname = @line[0];
   $tname = @line[1];
}
close (INFOS);
#
open (CLASSES, "<$fname");
#
$tline = 0;
$readheader = 1;
while (<CLASSES>) {
   chop;
   if ( $readheader == 1 ) {
      $header = $_;
      $readheader = 0;
   } else { 
      @line = split;
      $length = @line;
      if ( $length > 1 ) {
         @id = ( @id, @line[0] );
         @dd = ( @dd, @line[1] );
         @uv = ( @uv, @line[2] );
         @shear = ( @shear, @line[3] );
         @freq = ( @freq, @line[4] );
         @weight = ( @weight, @line[5] );
         @uu1 = ( @uu1, @line[6] );
         @uu2 = ( @uu2, @line[7] );
         @uu3 = ( @uu3, @line[8] );
         @uu4 = ( @uu4, @line[9] );
         @vv1 = ( @vv1, @line[10] );
         @vv2 = ( @vv2, @line[11] );
         @vv3 = ( @vv3, @line[12] );
         @vv4 = ( @vv4, @line[13] );
         @tt1 = ( @tt1, @line[14] );
         @tt2 = ( @tt2, @line[15] );
         @tt3 = ( @tt3, @line[16] );
         @tt4 = ( @tt4, @line[17] );
         $tline = $tline + 1;
#
#### Calculate the weight for wind energy
#
         @eweight = ( @eweight, @line[2]**3 * @line[4] );
#
      }
   }
}
#
### sort the list acooring the frequency (from high to low)
#
for ( $i=0; $i<$tline-1; $i++ ) {
   for ( $j=$i+1; $j<$tline; $j++ ) {
      if ( @eweight[$i] < @eweight[$j] ) {
         swap( @id[$i], @id[$j] ); 
         swap( @dd[$i], @dd[$j] ); 
         swap( @uv[$i], @uv[$j] ); 
         swap( @shear[$i], @shear[$j] ); 
         swap( @freq[$i], @freq[$j] ); 
         swap( @weight[$i], @weight[$j] ); 
         swap( @uu1[$i], @uu1[$j] ); 
         swap( @uu2[$i], @uu2[$j] ); 
         swap( @uu3[$i], @uu3[$j] ); 
         swap( @uu4[$i], @uu4[$j] ); 
         swap( @vv1[$i], @vv1[$j] ); 
         swap( @vv2[$i], @vv2[$j] ); 
         swap( @vv3[$i], @vv3[$j] ); 
         swap( @vv4[$i], @vv4[$j] ); 
         swap( @tt1[$i], @tt1[$j] ); 
         swap( @tt2[$i], @tt2[$j] ); 
         swap( @tt3[$i], @tt3[$j] ); 
         swap( @tt4[$i], @tt4[$j] ); 
         swap( @eweight[$i], @eweight[$j] ); 
      }
#
   }
}
#
##############################
###### Print table
#   print " \n";
open (TABLE, ">$tname");
   printf TABLE "HEADER %s \n", $header;
   printf TABLE "HEADER %6s %7s %6s %6s %7s %8s %11s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %6s \n",
   "id",  "dd", "uv", "shear", "freq", "weight", "eweight",
   "uu1", "uu2", "uu3", "uu4",
   "vv1", "vv2", "vv3", "vv4",
   "tt1", "tt2", "tt3", "tt4",
   "status";
for ( $i=0; $i<$tline; $i++ ) {
   printf TABLE "%12s %7.3f %6.3f %6.3f %7.4f %8.2f %11.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f %1s \n",
   @id[$i],  @dd[$i], @uv[$i], @shear[$i], @freq[$i], @weight[$i], @eweight[$i],
   @uu1[$i], @uu2[$i], @uu3[$i], @uu4[$i],
   @vv1[$i], @vv2[$i], @vv3[$i], @vv4[$i],
   @tt1[$i], @tt2[$i], @tt3[$i], @tt4[$i],
   "q";
}
#
close (INFOS);
###############################
#
sub swap {
   $tmp = $_[0];
   $_[0] = $_[1];
   $_[1] = $tmp;
}
