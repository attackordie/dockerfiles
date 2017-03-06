#!/bin/bash
set -e

# These variables can be overridden by docker environment variables
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
USERNAME=${USERNAME:-docker}

create_user() {
	# If the home folder exists, set a flag.
	# Creating the user during container initialization often is anticipated
	# by the mount of a docker volume. In this case the home directory is already
	# present in the file system and adduser skips by default the copy of the
	# configuration files
	HOME_FOLDER_EXISTS=0
	if [ -d /home/$USERNAME ] ; then HOME_FOLDER_EXISTS=1 ; fi

	# Create a group with USER_GID
	if ! getent group ${USERNAME} >/dev/null; then
		echo "Creating ${USERNAME} group"
		groupadd -f -g ${USER_GID} ${USERNAME} 2> /dev/null
	fi

	# Create a user with USER_UID
	if ! getent passwd ${USERNAME} >/dev/null; then
		echo "Creating ${USERNAME} user"
		adduser --quiet \
		        --disabled-login \
				  --uid ${USER_UID} \
				  --gid ${USER_GID} \
				  --gecos 'Workspace' \
				  ${USERNAME}
	fi

	# If configuration files have not been copied, do it manually
	if [ $HOME_FOLDER_EXISTS ] ; then
		chown ${USER_UID}:${USER_GID} /home/${USERNAME}
		install -m 644 -g ${USERNAME} -o ${USERNAME} /etc/skel/.bashrc /home/${USERNAME}
		install -m 644 -g ${USERNAME} -o ${USERNAME} /etc/skel/.bash_logout /home/${USERNAME}
		install -m 644 -g ${USERNAME} -o ${USERNAME} /etc/skel/.profile /home/${USERNAME}
	fi
}

# Create the user
create_user

# Add the user to video group for HW acceleration (only Intel cards supported)
usermod -aG video ${USERNAME}

# Load the default ROS entrypoint
source /ros_entrypoint.sh "$@"
