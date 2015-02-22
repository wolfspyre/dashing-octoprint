#!/bin/bash

usage () {
  cat <<EOF
usage: $0 plugin-path parent-dir  dashboard-dir
plugin-path is expected to be the path where this repository is cloned.
dashboard-dir is expected to be the subdirectory of parent-dir where the dashing instance is stored.
parent-dir is the parent directory, wherein conf.d will be created if it does not exist.
EG: $0 /home/pi/dashing-plugins/octoprint /home/pi/ my_dashboard
Debug statements will be output if the variable DEBUG exists; Example:
  DEBUG=true; $0 plugin-location dashboard-location
EOF
}

error () {
  MSG=$1
  echo -e "\033[31mERROR\033[0m: $MSG" >>/dev/stderr
}

warn () {
  MSG=$1
  echo -e "\033[1;33mWARN\033[0m: $MSG" >>/dev/stderr
}

info () {
  MSG=$1
  echo -e "\033[32mINFO\033[0m: $MSG"
}

debug () {
  MSG=$1
  if [ -n "$DEBUG" ]; then
      echo -e "\033[34mDEBUG\033[0m: \033[32m${FUNCNAME[1]}()\033[0m: $MSG"
  fi
}
PLUGIN_PATH=$1
DASH_ROOT=$2
DASH_PATH=$3
cd ${PLUGIN_PATH}

#validate if dirs are / padded
DASH_FULLPATH="$2/$3"

#TODO: make a deployFile function
deployFile() {
  _SOURCE = $1
  _DEST   = $2
  _TYPE   = $3
  debug "Source: ${_SOURCE}"
  debug "Dest: ${_DEST}"
  debug "Type: ${_TYPE}"
}
#it should take source, dest, and type of file. error if we can't make it so
# make dir, link.

#validate dirs are sane
for sane_dir in  ${PLUGIN_PATH} ${DASH_FULLPATH}; do
  #check to see if it's not a directory
  if (( ! -d ${sane_dir} )); then
    #if nort, is it a link?
    if (( -l ${sane_dir} )); then
      debug "${sane_dir} is a link."
    else
      #it's neither. crap. die
      error "${sane_dir} not a directory or a link"
      exit 1
    fi
  else
    debug "${sane_dir} exists"
  fi
done
#validate required bins are sane


#check for conf.d
if (( -d "${DASH_ROOT}/conf.d" )); then
  debug "${DASH_ROOT}/conf.d is a directory"
#if it's not a dir, is it a link?
elif (( -l "${DASH_ROOT}/conf.d")); then
  debug "${DASH_ROOT}/conf.d is a link"
#create it if not
else
  info "${DASH_ROOT}/conf.d doesn't exist. Creating it."
  mkdir "${DASH_ROOT}/conf.d"
fi
#deploy config default file
if (( -f "${DASH_ROOT}/conf.d/octoprint_defaults.yaml" )); then
  debug "${DASH_ROOT}/conf.d/octoprint_defaults.yaml exists"
  #it exists
else
  info "${DASH_ROOT}/conf.d/octoprint_defaults.yaml doesn't exist. Symlinking ${PLUGIN_PATH}/conf.d/octoprint_defaults.yaml to it"
  #symlink it if it doesn't
  ln -s "${PLUGIN_PATH}/conf.d/octoprint_defaults.yaml" "${DASH_ROOT}/conf.d/octoprint_defaults.yaml"
fi

#symlink widgets
for widget in  octocam octoprint; do
if (( -f "${DASH_FULLPATH}/widgets/${widget}" )); then
  debug "${DASH_FULLPATH}/widgets/${widget} exists"
  #it exists
else
  #symlink it if it doesn't
    info "${DASH_FULLPATH}/widgets/${widget} doesn't exist. Symlinking ${PLUGIN_PATH}/widgets/${widget} to it."
  ln -s "${PLUGIN_PATH}/widgets/${widget}" "${DASH_FULLPATH}/widgets/${widget}"
fi
#symlink jobs
for job in  octocam_shapshot; do
if (( -f "${DASH_FULLPATH}/jobs/${job}" )); then
  debug "${DASH_FULLPATH}/jobs/${job} exists"
  #it exists
else
  #symlink it if it doesn't
  ln -s "${PLUGIN_PATH}/jobs/${job}" "${DASH_FULLPATH}/jobs/${job}"
fi

#copy dashboard target
if (( -f "${DASH_FULLPATH}/dashboards/octoprint.erb" )); then
  #it exists
else
  #symlink it if it doesn't
ln -s "${PLUGIN_PATH}/dashboards/octoprint.erb" "${DASH_FULLPATH}/dashboards/octoprint.erb"
fi


#optional cronjob?
