#!/usr/bin/tclsh
# Filter program for QD spectral data. The design is to reject spikes.
# An optional conversion of wavelength into energy is performed.
#Adjusts for a model of quantum sensitivity of photomultiplier tube

proc writeconfig {} {
global opts
set configfilename [file join "~" ".filterrc2"]
set configfile [open $configfilename w]

   log "writing config to $configfilename"
   foreach {option value} [array get opts] {
      puts $configfile "setopt $option $value"
      log "Writeconfig: $option = $value"
   }
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

proc sensitivity {ev} {
#Derived from fitting a polynomial curve to data extracted from RCA documents in Excel
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
   set filename [file join $directory "log-filter-$timestamp.log"]
   set logfile [open $filename w]
   log "log starting at $timestamp"
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
   log "starting data load from $fname"
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
   log "read $linecount lines from file."
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
      set ev $currentdata($i.ev)
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
      set currentdata($i.ev) [lambdatoev $currentdata($i.lambda)]
      set currentdata($i.corrected) [expr {$currentdata($i.intensity)/[sensitivity $currentdata($i.ev)]}]
   }
}

proc orderby {{colname "none"}} {
global currentdata
   
   log "Sorting by $colname"
   set returndata {}
   if {[string equal -nocase $colname "none"]} {
      for {set i 1} {$i <= $currentdata(linecount)} {incr i} {
         lappend returndata $i
      }
   } {
      set sortdata {}
      for {set i 1} {$i <= $currentdata(linecount)} {incr i} {
         lappend sortdata [list $i $currentdata($i.$colname)]
      }
      set sortdata [lsort -real -index 1 $sortdata]
      foreach l $sortdata {
         lappend returndata [lindex $l 0]
      }
   }
   log "Order: $returndata"
   return $returndata
}

proc writedata {fname} {
global currentdata
global opts

   log "writing data to file: $fname"
   set outfile [open $fname w]
   set rejects [open "$fname.reject" w]
   puts $outfile "rescaled! delta:$opts(delta) thresh:$opts(threshold) $currentdata(comment)"
   puts $outfile "ev\tlockin sr510\tdmm kiethley 199"
   puts $rejects "rejected! delta:$opts(delta) thresh:$opts(threshold) $currentdata(comment)"
   puts $rejects "ev\tcorrected intensity\tdmm kiethley 199"
   set linecount 0
   set rejectcount 0
   foreach i $currentdata(sortorder) {
      set output {}
      lappend output [format "%0.12f" $currentdata($i.ev)]
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
   log "wrote $rejectcount line to rejects."
   log "wrote $linecount lines to output. done."
   close $outfile
   close $rejects
}

# Syntactic sugar for dealing with options
proc setopt {option {value 1}} {
global opts
   set opts($option) $value
}

proc getopt {option} {
global opts
   if {[llength [array names opts -exact $option]] == 0} {
      return 0
   } {
      return $opts($option)
   }
}

proc logopts {} {
global opts
   log "Options in effect:"
   foreach {option value} [array get opts] {
      log "--$option=$value"
   }
}

# command line Parsing
proc setoption {optstring} {
global opts
   log "setoption: $optstring"
   set base [string range $optstring 2 end]
   set optval [split $base =]
   if {[llength $optval]==1} {
      log "Commandline, setting $optval to 1"
      set opts($optval) 1
   } {
      set option [lindex $optval 0]
      set value [lindex $optval 1]
      log "Commandline, setting $option to $value"
      set opts($option) $value
   }
}

proc charoptions {optstring} {
global opts
   #stub
   log "charoptions: $optstring"
   log "charoptions is not yet implimented."
}

proc parseargs {} {
# parses arguments and returns a list of filenames to process
global argv
set filenames {}
set restasfilenames 0
set readstdin 0

   log "Parsing command line."
   log "ARGV:"
   log $argv
   foreach element $argv {
      log "Element: $element"
      if {$restasfilenames} {
         lappend filenames $element
      } {
         switch -glob $element {
            -          {set readstdin 1}
            --         {set restasfilenames 1}
            --*        {setoption $element}
            -[A-Za-z]* {charoptions $element}
            default {lappend filenames $element}
         }
      }
   }
   if {$readstdin} {
      while {! [eof stdin]} {
         gets stdin fname
         if {! [eof stdin]} {lappend filenames $fname}
      }
   }
   return $filenames
}

# gui callibacks start here

# start of global initilization
set currentdata(comment) empty.
startlog [file dirname argv0]
set configfile [file join "~" ".filterrc2"]
log "config file: [file nativename $configfile]"
if [file exists $configfile] {
   log "reading configuration from $configfile"
   source $configfile
} {
   log "FATAL ERROR: No .filterrc2 found."
   closelog
   exit
}
#testing stuff starts here.

#testing stuff ends here.

# Main loop
set filenames [parseargs]
log "Files: $filenames"
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
      set currentdata(sortorder) [orderby "ev"]
      writedata "[file rootname $fname].out.dat"
      log "Done with file $fname"
   }
}
closelog
