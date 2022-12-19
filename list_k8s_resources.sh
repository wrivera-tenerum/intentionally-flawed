#!/bin/bash
# Purpose: Outputs all the resources in a given namespace, or all namespaces.
# Optionally, can output to a collection of CSV files, 1 for every resource type.
# Author: Will Rivera
# ------------------------------------------

Help()
{
   # Display Help
   echo "Outputs all resources for a given namespace."
   echo ""
   echo "Syntax: list_all_gke_resources.sh [-n|o|d|h]"
   echo "options:"
   echo "   -n     A namespace to filter the output. Default: all"
   echo "   -o     The output format. [listjson|yaml|csv] Default: all"
   echo "   -d     The directory to output results relative to working directory. "
   echo "          Only works when -o is set to json, yaml, or csv."
   echo "          default: output"
   echo "   -h     Print this Help."
   echo ""
}

#Setting default values
export THISNS="all"
export THISOUTPUT="list"
export THISDIR="output"

#Checking passed variables to see if anything needs to be overridden

while getopts ":h:n:o:d:" options; do
  case "${options}" in  
    h) # display Help
      Help
      exit;;                   
    n)                                    # If the option is n,
      export THISNS=${OPTARG}                      # set $THISNS to specified value.
      echo $THISNS
      ;;
    o)                                    # If the option is o,
      export THISOUTPUT=${OPTARG}                     # Set $THISOUTPUT to specified value.
      ;;
    d)                                    # If the option is d,
      export THISDIR=${OPTARG}                     # Set $THISDIR to specified value.
      ;;
    *)                                    # If unknown (any other) option:
      help                      # display help.
      ;;
  
done
clear


ThisTS=$(date +%Y-%m-%d-%T)

if [ "$THISNS" == "ALL" ] || [ "$THISNS" == "all" ] || [ "$THISNS" == "All" ]; then
  export NAMESPACEQ="--all-namespaces"
  echo "Checking each API and CRD to see if there are any manifests defined for this type in any namespace."
else
  export NAMESPACEQ="-n $THISNS"
  echo "Checking each API and CRD to see if there are any manifests within the $THISNS Namespace."
fi

if [ "$THISOUTPUT" == "csv" ] || [ "$THISOUTPUT" == "yaml" ] || [ "$THISOUTPUT" == "json" ]; then
  
  #Make output directory if needed
  mkdir $THISDIR -p

  #Cleaning up any existing CSV files previously output.
  rm $THISDIR/gke_resources-*.* -f

fi

for i in $(kubectl api-resources --verbs=list --namespaced -o name | grep -v "events.events.k8s.io" | grep -v "events" | sort | uniq); do
  echo "Resource:" $i
  if [ "$THISOUTPUT" == "csv" ]; then
    kubectl get ${i} --ignore-not-found $NAMESPACEQ -o json | jq -r '["Name","Namespace","ResourceType","Kind","Created"],(.items[] | [.metadata.name, .metadata.namespace, .type, .kind, .metadata.creationTimestamp]) | @csv' >> $THISDIR/gke_resources-$i-$ThisTS.csv
  else
    if [ "$THISOUTPUT" == "json" ] || [ "$THISOUTPUT" == "yaml" ]; then
      kubectl get ${i} --ignore-not-found $NAMESPACEQ -o $THISOUTPUT >> $THISDIR/gke_resources-$i-$ThisTS.$THISOUTPUT
    else
      kubectl get ${i} --ignore-not-found $NAMESPACEQ 
    fi
  fi
done

if [ "$THISOUTPUT" == "csv" ] || [ "$THISOUTPUT" == "yaml" ] || [ "$THISOUTPUT" == "json" ]; then
  echo ""
  echo "All data output to $THISDIR directory"
else
  echo ""
  echo "Finished collecting data."
fi


