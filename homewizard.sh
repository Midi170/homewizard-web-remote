
HOMEWIZARD_IP="192.168.1.2"
HOMEWIZARD_PW="yourpass"
PROFILEDIR="/home/user/.homewizard"

# Functions --------------------------------------------------------------------

# ------------------------------------------------------------------------------
control_c()
# ------------------------------------------------------------------------------
#
# Description:  run if user hits control-c
#
# Parameter  :  none
#
# Output     :  logging
#
{
if [ $DEBUG -ge 3 ]; then set -x
fi

echo ""
}

# ------------------------------------------------------------------------------
gethumidity()
# ------------------------------------------------------------------------------
#
# Description:  return the humidity of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  echo `cat $PROFILEDIR/homewizard.json | jq '.thermometers | .[] | select(.name=='\"$1\"') | .hu'`
}

# ------------------------------------------------------------------------------
getstatus()
# ------------------------------------------------------------------------------
#
# Description:  return the state of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  echo `cat $PROFILEDIR/homewizard.json | jq '.switches | .[] | select(.name=='\"$1\"') | .status' | sed 's/\"//g'`
}

# ------------------------------------------------------------------------------
gettemperature()
# ------------------------------------------------------------------------------
#
# Description:  return the temperature of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  echo `cat $PROFILEDIR/homewizard.json | jq '.thermometers | .[] | select(.name=='\"$1\"') | .te'`
}

# ------------------------------------------------------------------------------
switch2id()
# ------------------------------------------------------------------------------
#
# Description:  converts switch to id
# 
# Parameter  :  <switchname> 
#
# Return     :  <id>
#
{
  if [ ! -r "$PROFILEDIR/homewizard.json" ]; then
    update_cache
  fi
  ID=`cat $PROFILEDIR/homewizard.json | jq '.switches | .[] | select(.name=='\"$1\"') | .id'`
  if [ -z "$ID" ] ; then
    echo -e "ID of Switch '$1' not found. Exiting..."
    exit 1
  else
    echo $ID
  fi
}


# ------------------------------------------------------------------------------
switch() 
# ------------------------------------------------------------------------------
#
# Description:  switch a switch on or off
# 
# Parameter  :  <switch> <on/off>
#
# Output     :  none
#
{
  SWITCH=`switch2id $1`
  wget -O /dev/null -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/sw/$SWITCH/$2
  sleep 1
  update_cache
}

# ------------------------------------------------------------------------------
update_cache()
# ------------------------------------------------------------------------------
#
# Description:  writes a json file of all switches of the homewizard
# 
# Parameter  :  none
#
# Output     :  none
#
{
  if [ ! -d "$PROFILEDIR" ]; then
    mkdir -p "$PROFILEDIR"
  fi
  wget -O - -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/get-sensors | jq '.response' > $PROFILEDIR/homewizard.json
}

# ------------------------------------------------------------------------------
usage()
# ------------------------------------------------------------------------------
#
# Description:  shows help text
# 
# Parameter  :  none
#
# Output     :  shows help text
#
{
cat << EOF

usage: $(basename $0) -d <switchdevice> -s <on/off>

OPTIONS:
  -l    list all  function
  -u    update all caches

examples:

  switch a device on or off
  $(basename $0) -d Loudspeaker -s on
  $(basename $0) -d Loudspeaker -s off

EOF
return 0
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# trap keyboard interrupt (control-c)
trap control_c SIGINT


# When you need an argument that needs a value, you put the ":" right after 
# the argument in the optstring. If your var is just a flag, withou any 
# additional argument, just leave the var, without the ":" following it.
#
# please keep letters in alphabetic order
#
while getopts ":d:ghs:tu" OPTION
do
  case $OPTION in
    d)
      GETOPTS_DEVICE="$OPTARG"
      ;;
    g)
      GETOPTS_GETSTATUS=1
      ;;
    h)
      GETOPTS_HUMIDITY=1
      ;;
    s)
      GETOPTS_SWITCH="$OPTARG"
      ;;
    t) 
      GETOPTS_TEMPERATURE=1
      ;;
    u)
      update_cache
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo -e "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ! -z $GETOPTS_SWITCH ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -s needs Option -d too"
    exit 1
  else
    switch $GETOPTS_DEVICE $GETOPTS_SWITCH
  fi
fi

if [ ! -z $GETOPTS_GETSTATUS ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -g needs Option -d too"
    exit 1
  else
    getstatus $GETOPTS_DEVICE $GETOPTS_SWITCH
  fi
fi

if [ ! -z $GETOPTS_HUMIDITY ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -h needs Option -d too"
    exit 1
  else
    gethumidity $GETOPTS_DEVICE 
  fi
fi

if [ ! -z $GETOPTS_TEMPERATURE ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -t needs Option -d too"
    exit 1
  else
    gettemperature $GETOPTS_DEVICE
  fi
fi

