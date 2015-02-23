#!/bin/bash

usage () {
  echo -e "Usage: $0 plugin-path parent-dir  dashboard-dir" >>/dev/stderr
  echo -e "  \033[1;33mplugin-path\033[0m:   The path where this repository is cloned." >>/dev/stderr
  echo -e "  \033[1;33mdashboard-dir\033[0m: The subdirectory of parent-dir where the dashing instance is stored." >>/dev/stderr
  echo -e "  \033[1;33mparent-dir\033[0m:    The directory wherein conf.d will be created if it does not exist." >>/dev/stderr
  echo -e "  \033[32mExample\033[0m: $0 \033[1;33m/home/pi/dashing-plugins/dashing-octoprint /home/pi/ my_dashboard\033[0m" >>/dev/stderr
  echo -e "Debug statements will be output if the variable DEBUG exists; " >>/dev/stderr
  echo -e "  \033[32mExample\033[0m: DEBUG=true $0 \033[1;33m/home/pi/dashing-plugins/dashing-octoprint /home/pi my_dashboard\033[0m" >>/dev/stderr
}

error () {
  MSG=$1
  echo -e "\033[31mERROR\033[0m: \033[32m${FUNCNAME[1]}()\033[0m: $MSG" >>/dev/stderr
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
  _SOURCE=$1
  _DEST=$2
  _TYPE=$3
  _FORCE=$4
  debug "Source: ${_SOURCE}"
  debug "Dest: ${_DEST}"
  debug "Type: ${_TYPE}"
  if [ ${_TYPE} == "link" ]; then
    if [ -e ${_SOURCE} ]; then
      debug "${_SOURCE} exists"
    else
      if [ $_FORCE ]; then
        #we were told to do our best to do the needful.
        error "${_SOURCE} exists. Force enabled. forcefully redeploying."
        rm -f ${_SOURCE};
        if [ $? == 0 ]; then
          ln -s ${_SOURCE} ${_DEST}
          info "${_SOURCE} forcefully linked to ${_DEST}"
        else
          error "something went wrong removing ${_SOURCE}".
          exit 1
        fi
      else
        #force not enabled. exit gracefully.
        error "${_SOURCE} cannot be the source, as it does not exist"
        exit 1
      fi
    fi
    if [ -e ${_DEST} ]; then
      debug "${_DEST} exists"
      if [ -L ${_DEST} ]; then
        debug "${_DEST} is a symlink"
      else
        error "${_DEST} exists, but is not a symlink"
        exit 1
      fi
    else
      debug "${_DEST} does not exist. Linking"
      ln -s ${_SOURCE} ${_DEST}
    fi
  else
    error "only link file type supported for deployFile"
    exit 1
  fi
}
#it should take source, dest, and type of file. error if we can't make it so
# make dir, link.




valDir() {
  _dir=$1
  debug "${_dir}"
  #check to see if it's not a directory
  if [ -d ${sane_dir} ]; then
    debug "${sane_dir} is a dir"
    return
  elif [ -l ${sane_dir} ]; then
    debug "${sane_dir} is a link."
  else
    #it's neither. crap. die
    error "${sane_dir} not a directory or a link"
    exit 1
  fi
}

checkConfD(){
  #check for conf.d
  if [ -e "${DASH_ROOT}/conf.d" ]; then
    debug "${DASH_ROOT}/conf.d exists"
    if [ -d "${DASH_ROOT}/conf.d" ]; then
      #is a directory
      linkConf
    elif [ -L "${DASH_ROOT}/conf.d" ]; then
      #is a link
      linkConf
    else
      error "${DASH_ROOT}/conf.d exists, but is not a directory or a link. Fix this."
      exit 1
    fi
  else
    debug "${DASH_ROOT}/conf.d doesn't exist. Creating it."
    mkdir "${DASH_ROOT}/conf.d"
    linkConf
  fi
}

linkConf(){
  info "linking default config"
  deployFile "${PLUGIN_PATH}/conf.d/octoprint_defaults.yaml" "${DASH_ROOT}/conf.d/octoprint_defaults.yaml" link
  linkWidgets
}

linkWidgets(){
  info "linking widget:"
  for widget in octocam octoprint; do
    info "    ${widget}"
    deployFile "${PLUGIN_PATH}/widgets/${widget}" "${DASH_FULLPATH}/widgets/${widget}" link
  done
  linkJobs
}

linkJobs(){
  info "Linking jobs:"
  for job in  octoprint_snapshot.rb ; do
    info "    $job"
    deployFile "${PLUGIN_PATH}/jobs/${job}" "${DASH_FULLPATH}/jobs/${job}" link
  done
  linkDashboard
}

linkDashboard(){
  info "linking Dashboard: octoprint.erb"
  deployFile "${PLUGIN_PATH}/dashboards/octoprint.erb" "${DASH_FULLPATH}/dashboards/octoprint.erb" link
  finishUp
}

finishUp(){
  echo -e "\033[32mDashing-Octoprint has been successfully installed!\033[0m">>/dev/stderr
  echo -e "\033[1;33mBe sure to restart dashing to pick up the changes.\033[0m">>/dev/stderr
  echo -e "Read the \033[1;33mREADME.MD\033[0m file for instructions on the octoprint_defaults.yaml file.">>/dev/stderr
}

#optional cronjob?
if [ $# -ne 3 ]; then
  usage
else
  #validate dirs are sane
  for sane_dir in  ${PLUGIN_PATH} ${DASH_FULLPATH}; do

    debug "${sane_dir}"
    valDir "${sane_dir}"
  done
  checkConfD
  #validate required bins are sane
fi
