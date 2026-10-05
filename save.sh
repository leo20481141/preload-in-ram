#!/usr/bin/bash

for file in ./services/*; do
	FILENAME="${file##*/}"
	SCRIPT="/usr/local/bin/${FILENAME}.sh"
	SERVICE="/etc/systemd/system/${FILENAME}.service"
	#SCRIPT="./${FILENAME}.sh"
	#SERVICE="./${FILENAME}.service"
	[ -f "${SCRIPT}" ] && rm "${SCRIPT}"
	[ -f "${SERVICE}" ] && rm "${SERVICE}"
	[ -d "${SCRIPT}" ] && continue
	[ -d "${SERVICE}" ] && continue
	while IFS= read -r line; do
		if [ ! "${line}" == "<<VARIABLES>>" ]; then
			echo "${line}" >> "${SCRIPT}"
			continue
		fi
		while IFS= read -r line; do
			echo "${line}" >> "${SCRIPT}"
		done < "${file}"
	done < "./template.sh"
	sed --posix "s/<<NAME>>/${FILENAME}/" "./template.service" > "${SERVICE}"
	chown root:root "${SCRIPT}"
	chown root:root "${SERVICE}"
	chmod +x "${SCRIPT}"
	sync
	systemctl daemon-reload
done
