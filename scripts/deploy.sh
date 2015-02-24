#!/bin/bash
################################################################################
# Edit these variables for different widget configurations.
#
PLUGIN_PATH=$1
DASH_ROOT=$2
DASH_PATH=$3
#TODO: validate if dirs are / padded
DASH_FULLPATH="$2/$3"
PLUGINNAME="Dashing-OctoPrint"
REPONAME='dashing-octoprint'
DEFAULTUSER='pi'
DEFAULTDASHBOARD='my_dashboard'
CONFDIR="${DASH_ROOT}/conf.d"
CONFFILE="octoprint_defaults.yaml"
declare -a WIDGETS=("octocam" "octoprint")
declare -a DASHBOARDS=("octoprint.erb")
declare -a JOBS=("octoprint_snapshot.rb" "octoprint_status.rb")
declare -a CREATE_DIRS=("assets/images/octocam")
################################################################################

usage () {
  echo -e "Usage: $0 plugin-path parent-dir  dashboard-dir" >>/dev/stderr
  echo -e "  \033[1;33mplugin-path\033[0m:   The path where this repository is cloned." >>/dev/stderr
  echo -e "  \033[1;33mdashboard-dir\033[0m: The subdirectory of parent-dir where the dashing instance is stored." >>/dev/stderr
  echo -e "  \033[1;33mparent-dir\033[0m:    The directory wherein conf.d will be created if it does not exist." >>/dev/stderr
  echo -e "  \033[32mExample\033[0m: $0 \033[1;33m/home/${DEFAULTUSER}/dashing-plugins/${REPONAME} /home/${DEFAULTUSER}/ ${DEFAULTDASHBOARD}\033[0m" >>/dev/stderr
  echo -e "Debug statements will be output if the variable DEBUG exists; " >>/dev/stderr
  echo -e "  \033[32mExample\033[0m: DEBUG=true $0 \033[1;33m/home/${DEFAULTUSER}/dashing-plugins/${REPONAME} /home/${DEFAULTUSER} ${DEFAULTDASHBOARD}\033[0m" >>/dev/stderr
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

cd ${PLUGIN_PATH}


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

valDir() {
  _dir=$1
  _force=$2
  debug "${_dir}"
  #check to see if it's not a directory
  if [ -e ${_dir} ]; then
    #it exists
    if [ -d ${_dir} ]; then
      debug "${_dir} is a dir"
      return
    elif [ -l ${_dir} ]; then
      debug "${_dir} is a link."
    fi
  else
    #it doesn't exist
    if [ $_force == "FORCE" ]; then
      #try to make the directory
      mkdir -p ${_dir}
      if [ $? = 0 ]; then
        info "Created ${_dir} successfully"
      else
        error "Could not create ${_dir}. Exiting"
        exit 1
      fi
    else
      #force not enabled. Directory does not exist.. crap. die
      error "${_dir} not a directory or a link"
      exit 1
    fi
  fi
}

checkConfD(){
  #check for conf.d
  if [ -e ${CONFDIR} ]; then
    debug "${CONFDIR} exists"
    if [ -d ${CONFDIR} ]; then
      #is a directory
      linkConf
    elif [ -L ${CONFDIR} ]; then
      #is a link
      linkConf
    else
      error "${CONFDIR} exists, but is not a directory or a link. Fix this."
      exit 1
    fi
  else
    debug "${CONFDIR} doesn't exist. Creating it."
    mkdir "${CONFDIR}"
    linkConf
  fi
}

linkConf(){
  info "linking config:"
  info "  ${CONFFILE}"
  deployFile "${PLUGIN_PATH}/conf.d/${CONFFILE}" "${CONFDIR}/${CONFFILE}" link
  linkWidgets
}

linkWidgets(){
  info "linking widget:"
  for _widget in ${WIDGETS[@]}; do
    info "  ${_widget}"
    deployFile "${PLUGIN_PATH}/widgets/${_widget}" "${DASH_FULLPATH}/widgets/${_widget}" link
  done
  linkJobs
}

linkJobs(){
  info "Linking jobs:"
  for _job in  ${JOBS[@]} ; do
    info "  ${_job}"
    deployFile "${PLUGIN_PATH}/jobs/${_job}" "${DASH_FULLPATH}/jobs/${_job}" link
  done
  linkDashboard
}

linkDashboard(){
  info "linking Dashboard:"
  for _dashboard in ${DASHBOARDS[@]}; do
    info "  ${_dashboard}"
    deployFile "${PLUGIN_PATH}/dashboards/${_dashboard}" "${DASH_FULLPATH}/dashboards/${_dashboard}" link
  done
  finishUp
}

finishUp(){
  echo -e "\033[32m${PLUGINNAME} has been successfully installed!\033[0m">>/dev/stderr
  echo -e "\033[1;33mBe sure to restart dashing to pick up the changes.\033[0m">>/dev/stderr
  echo -e "Read the \033[1;33mREADME.MD\033[0m file for instructions on the ${CONFFILE} file.">>/dev/stderr
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
  if [ $CREATE_DIRS ]; then
    info "creating directories if necessary"
    for _dir in ${CREATE_DIRS[@]}; do
      info "  ${DASH_FULLPATH}/${_dir}"
      valDir "${DASH_FULLPATH}/${_dir}" "FORCE"
    done
  fi
  checkConfD
  #validate required bins are sane
fi
