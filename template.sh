#!/usr/bin/bash

set -eu

DEBUG="false"
RAMDISK="/dev/shm"

<<VARIABLES>>

debug() {
	echo "$1"
	[ ! "$DEBUG" == "true" ] && return
	if [ ! -v LOGFILE ]; then
		echo "No log file defined."
		echo "Exitting..."
		exit 1
	fi
	echo "$1" >> "$LOGFILE"
}

synctoram() {
	local DISKDIR="${1}"
	local RAMDIR="${2}"
	local BACKUPDIR="${3}"
	if [ -d "${DISKDIR}" ] && [ ! -d "${BACKUPDIR}" ]; then
		local USER
		local GROUP
		local PERMS
		USER="$(stat -c%u "${DISKDIR}")"
		GROUP="$(stat -c%g "${DISKDIR}")"
		PERMS="$(stat -c%a "${DISKDIR}")"
		mv "${DISKDIR}" "${BACKUPDIR}"
		chown "${USER}:${GROUP}" "${BACKUPDIR}"
		chmod "${PERMS}" "${BACKUPDIR}"
		sync
		mkdir -p "${RAMDIR}"
		chown "${USER}:${GROUP}" "${RAMDIR}"
		chmod "${PERMS}" "${RAMDIR}"
		rsync -aq "${BACKUPDIR}/" "${RAMDIR}/"
		mkdir "${DISKDIR}"
		chown "${USER}:${GROUP}" "${DISKDIR}"
		chmod "${PERMS}" "${DISKDIR}"
		mount --bind "${RAMDIR}" "${DISKDIR}"
	fi

}

synctodisk() {
	local DISKDIR="${1}"
	local RAMDIR="${2}"
	local BACKUPDIR="${3}"
	if [ -d "${RAMDIR}" ] && [ -d "${BACKUPDIR}" ]; then
		local USER
		local GROUP
		local PERMS
		USER="$(stat -c%u "${BACKUPDIR}")"
		GROUP="$(stat -c%g "${BACKUPDIR}")"
		PERMS="$(stat -c%a "${BACKUPDIR}")"
		umount "${DISKDIR}"
		rm -r "${DISKDIR}"
		rsync -aq --delete "${RAMDIR}/" "${BACKUPDIR}/"
		mv "${BACKUPDIR}" "${DISKDIR}"
		chown "${USER}:${GROUP}" "${DISKDIR}"
		chmod "${PERMS}" "${DISKDIR}"
		sync
	fi
}

preload() {
	PRELOAD_DIR="${1}"
	[ ! -d "${PRELOAD_DIR}" ] && return
	find "${PRELOAD_DIR}" -type f -exec dd if="{}" of="/dev/null" status="none" \;
}

syncalltoram() {
	[ ! -v DISKDIRS ] && return
	[ ! -v RAMDIRS ] && return
	[ ! -v BACKUPDIRS ] && return
	[ ! "${#DISKDIRS[@]}" == "${#RAMDIRS[@]}" ] && return
	[ ! "${#DISKDIRS[@]}" == "${#BACKUPDIRS[@]}" ] && return
	LENGTH="${#DISKDIRS[@]}"
	for ((i=0; i<LENGTH; i++)); do
		synctoram "${DISKDIRS[i]}" "${RAMDIRS[i]}" "${BACKUPDIRS[i]}"
	done
}

syncalltodisk() {
	[ ! -v DISKDIRS ] && return
	[ ! -v RAMDIRS ] && return
	[ ! -v BACKUPDIRS ] && return
	[ ! "${#DISKDIRS[@]}" == "${#RAMDIRS[@]}" ] && return
	[ ! "${#DISKDIRS[@]}" == "${#BACKUPDIRS[@]}" ] && return
	LENGTH="${#DISKDIRS[@]}"
	for ((i=0; i<LENGTH; i++)); do
		synctodisk "${DISKDIRS[i]}" "${RAMDIRS[i]}" "${BACKUPDIRS[i]}"
	done
}

preloadall() {
	[ ! -v PRELOAD_DIRS ] && return
	for PRELOAD_DIR in "${PRELOAD_DIRS[@]}"; do
		preload "${PRELOAD_DIR}"
	done
}

if [ ! -v 1 ]; then
	echo "Usage: ${0} sync-to-ram or ${0} sync-to-disk"
	exit 1
fi

if [ -v 2 ]; then
	echo "only one argumment is accepted."
	exit 1
fi

if [ "${1}" == "sync-to-ram" ]; then
	debug "Syncing to ram..."
	syncalltoram
	preloadall
	debug "Finished syncing to ram."
	exit 0
fi

if [ "${1}" == "sync-to-disk" ]; then
	debug "Syncing to disk..."
	syncalltodisk
	debug "Finished syncing to disk."
	exit 0
fi

echo "Usage: ${0} sync-to-ram or ${0} sync-to-disk"
exit 1
