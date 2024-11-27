#!/bin/bash
set -e

EULA_FILE="$1"

# Handle EULA setting
EULA_ACCEPTED=

# EULA has been accepted already (ACCEPT_EULA is set in local.conf)
if grep -q '^\s*ACCEPT_EULA\s*=\s*["'\'']..*["'\'']' conf/local.conf;then
    EULA_ACCEPTED=1
fi

if [ -n "$EULA" -a -z "$EULA_ACCEPTED" ];then
    # The EULA is not set as accepted in local.conf, but the EULA
    # variable is set in the environment, so we just configure
    # ACCEPT_EULA in local.conf according to $EULA.
    echo "ACCEPT_EULA = \"$EULA\"" >> conf/local.conf
elif [ -z "$EULA_ACCEPTED" ];then
    # The EULA is not set as accepted in local.conf, and EULA is
    # not set in the environment, so we need to ask the user if they
    # accepts the EULA:
    cat <<EOF

Some parts of the BSP depend on libraries and packages from other providers
which are covered by the provider's End User License Agreement (EULA).
To have the right to use these binaries in your images, you need to read
and accept the following license agreement...

[Hit <ENTER> to continue]
EOF

    read

    more -d "$EULA_FILE"
    echo
    REPLY=
    while [ -z "$REPLY" ];do
        echo -n "Do you accept the EULA you just read? (y/n) "
        read REPLY
        case "$REPLY" in
            y|Y)
		echo "EULA has been accepted."
		echo "ACCEPT_EULA = \"1\"" >> conf/local.conf
		EULA=1
		;;
            n|N)
		echo "EULA has not been accepted."
		exit 1
		;;
            *)
		REPLY=
		;;
        esac
    done
else
    # The EULA has been accepted once, so ACCEPT_EULA is set
    # in local.conf.  No need to do anything.
    :
fi
