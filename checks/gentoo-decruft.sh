#!/bin/bash

logfile=/var/log/cruft.log

# Gentoo decruft Mode:
# logfile  logfile only (standard)
# revdep   logfile + revdep-rebuild
# move     logfile + revdep-rebuild + move file to *.cruft
# delete   logfile + revdep-rebuild + delete file
mode=logfile

# Rebuild Tool:
# revdep-rebuild from app-portage/gentoolkit
# reconcilio     from sys-apps/paludis
revtool=revdep-rebuild

# Run decruft modules:
#  lib  - System libraries
#  bin  - System binaries
#
decruft_modules="lib bin"
#decruft_modules="lib"

#################################################################
#  Global
#################################################################
# Color Definitions
NO="\x1b[0m"
BR="\x1b[0;01m"
RD="\x1b[31;01m"
GR="\x1b[32;01m"
YL="\x1b[33;01m"
BL="\x1b[34;01m"
RS="\x1b[35;01m"
CY="\x1b[36;01m"
BELL="\07"

### check needed tools
if [ -z "$(which qfile 2>/dev/null)" ]; then
   echo "No qfile found. Please install app-portage/portage-utils"
   exit 1
fi

if  [ "$mode" != "logfile" ] && [ -z "$(which "$revtool" 2>/dev/null)" ]; then
   echo "No $revtool found. Please install the rebuilder"
   exit 1
fi

get_dependency(){
  prepare_output "$GR" "$(qfile -qvC "$1" 2>/dev/null)"
}

build_blacklist_patterns(){

  # User Paths
   echo "/home/"
   echo "/usr/local/"

  # GCC cruft
   echo "libgcc_s.so.1"
   echo "/usr/bin/cc"
 
   allgcc="$(gcc-config -C -l | sed 's/\(.*\] \)\(.*\)\(-[0-9].*\)/\2/g' | grep -v ^$ )"
   curgcc="$(gcc-config -C -c | sed 's/-[0-9].*//g')"
   echo "$allgcc" | grep -v "$curgcc"

  # some configs (lica python-config
   echo "config"

  # nspluginwrapper installed plugins
   echo "nsbrowser/plugins/npwrapper"
}

check_blacklist(){
   echo "$blackpatterncache" | while read pattern; do
       if [ -n "$(echo "$1" | grep "$pattern")" ]; then
         prepare_output "$YL" "$pattern" "Blacklist:"
       fi
   done | head -n 1
}


decruft(){
# Decruft modes:
# logfile  logfile only (standard)
# revdep   logfile + revdep-rebuild(module lib only)
# move     logfile + revdep-rebuild + move file to *.cruft
# delete   logfile + revdep-rebuild + delete file

   cruftfile="$1"
   DM="$2"
   echo -e "$BELL"$YL"Check ${DM}: ""$RD""$cruftfile" "$NO"'-> '"$RD""cruft""$NO"

   "$DM"_pre_decruft "$cruftfile"

   # Allways
   echo "$cruftfile" >> "$logfile"

   if [ "$mode" == "move" ]; then
      echo "$GR"mv "$RD""$cruftfile" "$NO""$cruftfile".cruft
      mv "$cruftfile" "$cruftfile".cruft
   fi

   if [ "$mode" == "delete" ]; then
      echo -e "$GR"rm "$RD""$cruftfile""$NO"
      rm "$cruftfile"
   fi
}

check_symlink(){
  checkfile="$(readlink -f "$1")"
  if [ -e "$checkfile" ]; then
     dep="$("$DM"_get_dependency "$checkfile")"
     if [ -n "$dep" ]; then
         prepare_output "$CY" "$dep" "$checkfile"' ->' 
     fi
  fi
}

prepare_output(){
   #$1 = color code
   #$2 = dependency
   #$3 = prefix
   if [ -n "$2" ]; then
      if [ -z "$3" ]; then
         echo "$1""$2"
      else
         echo -e "$1""$3" "$2"
      fi
   fi
}

#################################################################
# Module lib
#################################################################
lib_supported(){
  echo "Run libraries check"
}


lib_get_paths(){
  # Scan default nomultilib paths
  if ! [ -d /usr/lib64 ] ; then
     echo /lib
     echo /usr/lib
  fi
  cat /etc/ld.so.conf | grep "^/" | while read libpath ; do
    if [ -n "$(echo "$libpath" | grep -v ^/home | grep -v ^/usr/local )" ]; then
       # Don't scan lib if lib64 exists
       if [ -d /usr/lib64 ] ; then
          extpath="$(echo "$libpath" |sed 's:/lib$:/lib64:' | sed 's:/lib/:/lib64/:' )"
          if [ "$extpath" == "$libpath" ]; then   #path already */lib64/*
             echo "$libpath"
          else
             if ! [ -d "$extpath" ]; then           # */lib64/* path does not exist, scan */lib/*
                echo "$libpath"
             fi
          fi
       else
          echo "$libpath"
       fi
    fi
  done
}

lib_get_files(){
#  libgcc_s.so.1   for GCC
   find $(lib_get_paths) \
     \( -type l -or -type f \)    \
     \( -regex '.*[.]so[.].*' -or \
        -regex '.*[.]so'      -or \
        -regex '.*[.]la' \)       | grep -v libgcc_s.so.1
}

lib_get_dependency(){
   checkfile="$1"
   if [ -L "$checkfile" ]; then
      dep="$(check_symlink "$checkfile")"
   else

      # check portage
      dep="$(get_dependency "$checkfile")"

      # check blacklist
      if [ -z "$dep" ]; then
         dep="$(check_blacklist "$checkfile")"
      fi

      # check the /lib64 -> /lib issue
      if [ -z "$dep" ]; then
         # check for wrong usage of */lib/* instead */lib64/*
         wrongfile="$(echo "$checkfile" | sed 's:/lib64/:/lib/:')"
         dep="$(get_dependency "$wrongfile")"
         dep="$(prepare_output "$YL" "$dep" 'lib64->lib:')"
      fi
   fi
   echo "$dep"
}

lib_pre_decruft(){
   cruftfile="$1"
   if ! [ "$mode" == "logfile" ]; then
      if [ -z "$( echo "$cruftfile" | grep '[.]debug$')" ]; then  #No rebuild for debug files
         if [ "$revtool" == "reconcilio" ]; then
            echo -e "$GR"reconcilio "$NO"--log-level silent --library "$RD""$(basename $cruftfile)""$NO"
            reconcilio --log-level silent --library "$(basename $cruftfile)"
         else
            # default is revdep-rebuild
            echo -e "$GR"revdep-rebuild "$NO"-i --library "$RD""$(basename $cruftfile)""$NO" -- -q"$NO"
            revdep-rebuild -i --library "$(basename $cruftfile)" -- -q
         fi
      fi
   fi
}


#################################################################
# Module bin
#################################################################
bin_supported(){
  echo "Run binaries check"
}

bin_get_path(){
   echo $PATH | sed 's/:/\n/g' | grep -v local | grep -v home
}

bin_get_files(){
   find $(bin_get_path) -type l -or -type f
}

bin_get_dependency(){
   checkfile="$1"
   if [ -L "$checkfile" ]; then
      dep="$(check_symlink "$checkfile" 2>/dev/null)"
   else

      # Check portage
      dep="$(get_dependency "$checkfile")"

      # Check blacklist
      if [ -z "$dep" ]; then
         dep="$(check_blacklist "$checkfile")"
      fi

      # check the /lib64 -> /lib issue
      if [ -z "$dep" ]; then
         # check for wrong usage of */lib/* instead */lib64/*
         wrongfile="$(echo "$checkfile" | sed 's:/lib64/:/lib/:')"
         dep="$(get_dependency "$wrongfile")"
         dep="$(prepare_output "$YL" "$dep" 'lib64->lib:')"
      fi

      # check GCC needed cruft! (gcc-config)
      if [ -z "$dep" ]; then
         wrongfile="$(basename "$checkfile")"
         dep="$(get_dependency "$wrongfile" | grep '/gcc-[0-9]' | head -n 1)"
         dep="$(prepare_output "$YL" "$dep" 'gcc-cruft:')"
      fi
   fi
   echo "$dep"
}

bin_pre_decruft(){
   # nothing to do
   echo -n ""
}

######################################################################################
# run checks
######################################################################################

blackpatterncache="$(build_blacklist_patterns)"

# Process modules
for DM in $decruft_modules; do

   # check module is supported
   if ! "$DM"_supported 2>/dev/null ; then
      echo "Module $DM not supported"
      exit 1
   fi
 
   "$DM"_get_files | while read checkfile; do

      # get package for file
      dep="$("$DM"_get_dependency  "$checkfile")"

      if [ -z "$dep" ]; then
         decruft "$checkfile" "$DM"
      else
         echo -e "$YL""Check $DM: ""$GR""$checkfile" '-> '"$dep""$NO"
      fi
   done
done
