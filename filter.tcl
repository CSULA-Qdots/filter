#!/usr/bin/tclsh
# Filter program for QD spectral data. The design is to reject spikes.
# An optional conversion of wavelength into energy is performed.
#Adjusts for a model of quantum sensitivity of photomultiplier tube

proc writeconfig {} {
#stub
}

proc makegui {} {
# stub
}

# Kind of some basic math. Mostly syntactic sugar.
proc max {a b} {
   return [expr {$a > $b ? $a : $b}]
}

proc min {a b} {
   return [expr {$a > $b ? $b : $a}]
}

proc lambdatoev {lambda} {
   return [expr {12398.419/$lambda}]
}

#Derived from fitting a polynomial curve to data extracted from RCA documents in Excel
proc sensitivity {ev} {
   return [expr {40.5593*($ev **4)-237.959*($ev **3)+514.331*($ev **2)-483.73*$ev+167.137}]
}

# Logging infrastructure. Logs are our freinds.
proc log {line} {
global logfile
   set timestamp [clock format [clock seconds] -format "%H%M%S"]
   puts $logfile "$timestamp : $line"
   puts "$timestamp : $line"
}

proc closelog {} {
global logfile
   set timestamp [clock format [clock seconds] -format "%Y%m%d%H%M%S"]
   log "Closing log at $timestamp"
   close $logfile
}

proc startlog {directory} {
global logfile

   set timestamp [clock format [clock seconds] -format "%Y%m%d%H%M%S"]
   set filename [file join $directory "log-$timestamp.log"]
   set logfile [open $filename w]
   log "Log starting at $timestamp"
   return $logfile
}

proc runaverage {start end {col "intensity"}} {
global currentdata
set sum 0

   for {set i $start} {$i <= $end} {incr i} {
      set sum [expr {$sum + $currentdata($i.$col)}]
   }
   return [expr {$sum / ($end - $start + 1)}]
}

proc loaddata {fname} {
global currentdata
variable line

   unset currentdata
   log "Starting data load from $fname"
   set infile [open $fname "r"]
   gets $infile comment
   gets $infile line
   set currentdata(comment) $comment
   set currentdata(header) $line
   set linecount 0
   while {![eof $infile]} {
      gets $infile line
      set line [split $line]
      if {[llength $line]} {
         incr linecount
         set currentdata($linecount.lambda) [lindex $line 0]
         set currentdata($linecount.intensity) [lindex $line 1]
         set currentdata($linecount.temp) [lindex $line 2]
      }
   }
   set currentdata(linecount) $linecount
   log "Read $linecount lines from file."
   close $infile
}

proc buildrejects {} {
global currentdata
global opts
set rejectlist {}

   for {set i 1} {$i <= $currentdata(linecount)} {incr i} {
      set first [max 1 [expr {$i - $opts(delta)}]]
      set last [min $currentdata(linecount) [expr {$i + $opts(delta)}]]
      set avg [runaverage $first $last]
      set deviation [expr {abs(($currentdata($i.intensity)-$avg)/$avg)}]
      set wl $currentdata($i.lambda)
      set ev $currentdata($i.eV)
      if {(($wl >= 7000) && ($wl <=7800)) || (($wl >=10300)&&($wl <= 11600))} {
         lappend rejectlist $i
      }
      if {$deviation > $opts(threshold)} {
         lappend rejectlist $i
      }
   }
   set currentdata(rejectlist) $rejectlist
   return $rejectlist
}

proc process {} {
global currentdata
   
   for {set i 1} {$i <= $currentdata(linecount)} {incr i} {
      set currentdata($i.eV) [lambdatoev $currentdata($i.lambda)]
      set currentdata($i.corrected) [expr {$currentdata($i.intensity)/[sensitivity $currentdata($i.eV)]}]
   }
}

proc writedata {fname} {
global currentdata
global opts

   log "Writing data to file: $fname"
   set outfile [open $fname w]
   set rejects [open "$fname.reject" w]
   puts $outfile "Rescaled! delta:$opts(delta) thresh:$opts(threshold) $currentdata(comment)"
   puts $outfile "eV\tLockin SR510\tDMM Kiethley 199"
   puts $rejects "Rejected! delta:$opts(delta) thresh:$opts(threshold) $currentdata(comment)"
   puts $rejects "eV\tCorrected Intensity\tDMM Kiethley 199"
   set linecount 0
   set rejectcount 0
   for {set i 1} {$i <= $currentdata(linecount)} {incr i} {
      set output {}
      lappend output [format "%0.12f" $currentdata($i.eV)]
      lappend output [format "%0.12f" $currentdata($i.corrected)]
      lappend output [format "%0.12f" $currentdata($i.temp)]
      if {[lsearch -exact $currentdata(rejectlist) $i] == -1} {
         incr linecount
         puts $outfile [join $output "\t"]
      } {
         incr rejectcount
         puts $rejects [join $output "\t"]
      }
   }
   log "Wrote $rejectcount line to rejects."
   log "Wrote $linecount lines to output. Done."
   close $outfile
   close $rejects
}

# GUI callibacks start here

# Start of global initilization
set currentdata(comment) Empty.
startlog [file dirname argv0]
set configfile [file join "~" ".filterrc"]
log "Config file: [file nativename $configfile]"
if [file exists $configfile] {
   log "Reading configuration from $configfile"
   source $configfile
   log "Done"
   log "Operator= $opts(operator)"
   log "Delta= $opts(delta)"
   log "Threshold= $opts(threshold)"
} {
   log "Creating default config."
   set opts(delta) 3
   set opts(threshold) 3
   set opts(datadir) ""
   set opts(operator) "Unknown"
#   log "Writing config to $configfile"
#   writeconfig
   log Done.
}

#testing stuff starts here.

#testing stuff ends here.

# Main loop
log "ARGV:"
log $argv
set filenames {}
if {[string compare "-" [lindex $argv 0]]!=0} {
   foreach fname $argv {
      set dirname [file dirname $fname]
      set globname [file tail $fname]
      set filenames [concat $filenames [glob -dir $dirname $globname]]
      unset dirname
      unset globname
   }
} {
   while {! [eof stdin]} {
      gets stdin fname
      if {! [eof stdin]} {lappend filenames $fname}
   }
}
log $filenames
foreach fname $filenames {

   log "--"
   if {[string match -nocase "*.out.dat" $fname]} {
      log "Not processing $fname"
   } {
      loaddata $fname
      log "Adding eV."
      process
      log "Done"
      log "Building reject list:"
      log [buildrejects]
      log Done.
      writedata "[file rootname $fname].out.dat"
      log "Done with file $fname"
   }
}
closelog
