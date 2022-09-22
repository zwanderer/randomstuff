#!/bin/sh

#ADBLOCKLISTS=" \
#https://easylist-downloads.adblockplus.org/easylist.txt \
#https://easylist-downloads.adblockplus.org/easyprivacy.txt \
#https://easylist-downloads.adblockplus.org/adwarefilters.txt \
#https://easylist-downloads.adblockplus.org/fanboy-annoyance.txt \
#https://easylist-downloads.adblockplus.org/malwaredomains_full.txt \
#https://raw.githubusercontent.com/Dawsey21/Lists/master/adblock-list.txt \
#http://www.kiboke-studio.hr/i-dont-care-about-cookies/abp/ \
#https://easylist-downloads.adblockplus.org/antiadblockfilters.txt"

ADBLOCKLISTS=" \
https://easylist-downloads.adblockplus.org/easylist.txt \
https://easylist-downloads.adblockplus.org/easyprivacy.txt \
https://raw.githubusercontent.com/Dawsey21/Lists/master/adblock-list.txt \
https://easylist-downloads.adblockplus.org/antiadblockfilters.txt \
https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt"

ROOTDIR="/jffs"
CONFDIR="${ROOTDIR}/privoxy"
TMPDIR="/tmp"
SCRIPT_NAME=$(basename "${0}" ".sh")
LOCKFILE="$TMPDIR/$SCRIPT_NAME.lck"
LASTRUNFILE="$TMPDIR/$SCRIPT_NAME.lastdl"
DBG=0
LOG=0
ANY_DOWNLOAD=0
CA_PATH=/opt/etc/ssl/certs

debug()
{
    [ $LOG == 0 ] && [ $DBG -ge $2 ] && echo "${SCRIPT_NAME}: $1"
    [ $LOG == 1 ] && [ $DBG -ge $2 ] && logger "${SCRIPT_NAME}: $1"
}

usage()
{
    echo "${SCRIPT_NAME} is a script to convert AdBlockPlus lists into Privoxy-lists and install them."
    echo " "
    echo "Options:"
    echo "      -h:    Show this help."
    echo "      -q:    Don't give any output."
    echo "      -v:    Enable verbosity. Show a little bit more output."
    echo "      -l:    Redirect output into syslog instead of stdout."
}

wait_for_connection()
{
    while :; do
        ping -c 1 -w 10 www.google.com > /dev/null 2>&1 && break
        sleep 60
        debug "Retrying internet connection..." 1
    done
}

download_file()
{
    ATTEMPT=1
    OUTPUT_FILE="$2"
    HTTP_CODE="$2.http"

    while :; do
        [ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"
        [ -f "$HTTP_CODE" ] && rm "$HTTP_CODE"

        # Skip URL after 3 failed attempts...
        if [ $ATTEMPT = 4 ]; then
          debug "gen_host: Skipping $1 ..." 1
          return 1
        fi

        debug "Downloading $1 (attempt $ATTEMPT)..." 0
        (curl -o "$OUTPUT_FILE" --silent --write-out '%{http_code}' --connect-timeout 90 --max-time 150 --capath $CA_PATH -L "$1" > "$HTTP_CODE") & DOWNLOAD_PID=$!

        wait $DOWNLOAD_PID
        RESULT=$?
        HTTP_RESULT=$(cat "$HTTP_CODE")
        rm "$HTTP_CODE"

        if [ $RESULT = 0 ] && [ $HTTP_RESULT = 200 ]; then
            debug "Download succeeded [ $1 ]..." 0
            ANY_DOWNLOAD=1
            return 0
        else
            debug "Download failed [ $HTTP_RESULT $RESULT ]..." 1
            ATTEMPT=$(($ATTEMPT + 1))
            sleep 10
        fi
    done
}

timeout()
{
    if [ -f "$LOCKFILE" ]; then
        debug "Execution timed out." 0
        PID=$(cat $LOCKFILE)
        kill -TERM $PID
        [ "$$" != "$PID" ] && kill -TERM $$
        rm $LOCKFILE
    fi
}

startup()
{
    # check for dependencies
    DEPENDENCIES="curl grep privoxy sed sort wc cut logger"
    for COMMAND in ${DEPENDENCIES}
    do
        type -p "${COMMAND}" &>/dev/null && continue || {
            debug "The following dependency is missing: (${COMMAND})." 0
            exit 1
        }
    done

    CURRENT_TIME=$(date +%s)

    # Time hasn't been set yet
    if [ $CURRENT_TIME -lt 3600 ]; then
      debug "Ran before NTP, quiting." 0
      exit 1
    fi

    # Check if the script ran less than 6 hours ago, to avoid spamming downloads
    if [ -f "$LASTRUNFILE" ] && [ $(($CURRENT_TIME - $(cat $LASTRUNFILE))) -lt 21600 ]; then
      debug "Last run happened less than 6 hours ago, quiting." 0
      #exit 1
    fi

    # Makes sure only one instance of this script is running
    if [ -f "$LOCKFILE" ]; then
      debug "Already running, quitting." 0
      exit 1
    fi

    echo -n $$ > "$LOCKFILE"

    sleep 1

    # Check for race conditions, when 2 instances start at the same time
    if [ "$(cat $LOCKFILE)" != "$$" ]; then
      debug "Race condition, quiting." 0
      exit 1
    fi

    debug "Started..." 0

    # The script must run within 1200 seconds, this will create a timer to terminate it
    (sleep 1200 && timeout) & TIMEOUT_PID=$!
}

shutdown()
{
    [ ! -z "$TIMEOUT_PID" ] && kill -KILL $TIMEOUT_PID
    rm "$LOCKFILE"
    exit $1
}

main()
{
    cp -f /tmp/privoxy.conf ${TMPDIR}/new.privoxy.conf
    for URL in ${ADBLOCKLISTS}
    do
        FILE="${TMPDIR}/$(basename "${URL}" .txt).tmp"
        ACTIONFILE=${FILE%\.*}.script.action
        FILTERFILE=${FILE%\.*}.script.filter
        LIST=$(basename "${FILE%\.*}")

        download_file $URL $FILE
        if [ $? = 0 ]; then
            [ "$(grep -E '^\[Adblock.*\]$' ${FILE})" == "" ] && debug "The file received isn't an AdBlockPlus list. Skipping {$URL} ..." 0 && continue

            # convert Adblock Plus list to Privoxy list
            debug "Creating actionfile for ${LIST} ..." 1
            echo -e "{ +block{${LIST}} }" > "${ACTIONFILE}"

            # blacklist of urls
            sed '/^!.*/d;1,1 d;/^@@.*/d;/\$.*/d;/#/d;s/\./\\./g;s/?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${FILE} >> ${ACTIONFILE}

            debug "Creating filterfile for ${LIST} ..." 1
            echo "FILTER: ${LIST} Tag filter of ${LIST}" > "${FILTERFILE}"

            # set filter for HTML elements
            sed '/^#/!d;s/^##//g;s/^#\(.*\)\[.*\]\[.*\]*/s@<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>@@g/g;s/^#\(.*\)/s@<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>@@g/g;s/^\.\(.*\)/s@<([a-zA-Z0-9]+)\\s+.*class=.?\1.*>.*<\/\\1>@@g/g;s/^a\[\(.*\)\]/s@<a.*\1.*>.*<\/a>@@g/g;s/^\([a-zA-Z0-9]*\)\.\(.*\)\[.*\]\[.*\]*/s@<\1.*class=.?\2.*>.*<\/\1>@@g/g;s/^\([a-zA-Z0-9]*\)#\(.*\):.*[:[^:]]*[^:]*/s@<\1.*id=.?\2.*>.*<\/\1>@@g/g;s/^\([a-zA-Z0-9]*\)#\(.*\)/s@<\1.*id=.?\2.*>.*<\/\1>@@g/g;s/^\[\([a-zA-Z]*\).=\(.*\)\]/s@\1^=\2>@@g/g;s/\^/[\/\&:\?=_]/g;s/\.\([a-zA-Z0-9]\)/\\.\1/g' ${FILE} >> ${FILTERFILE}

            echo "\n{ +filter{${LIST}} }" >> "${ACTIONFILE}"
            echo "*" >> "${ACTIONFILE}"

            # install Privoxy actionsfile
            mv -f "${ACTIONFILE}" "${CONFDIR}"
            if [ "$(grep "$(basename "${ACTIONFILE}")" ${TMPDIR}/new.privoxy.conf)" == "" ]; then
                debug "Adding actionfile entry..." 1
                sed "s/^actionsfile user\.action/actionsfile $(basename "${ACTIONFILE}")\nactionsfile user.action/" -i ${TMPDIR}/new.privoxy.conf
            fi

            # install Privoxy filterfile
            mv -f "${FILTERFILE}" "${CONFDIR}"
            if [ "$(grep "$(basename "${FILTERFILE}")" ${TMPDIR}/new.privoxy.conf)" == "" ]; then
                debug "Adding filterfile entry..." 1
                sed "s/^\(#*\)filterfile default\.filter/filterfile $(basename "${FILTERFILE}")\n\1filterfile default.filter/" -i ${TMPDIR}/new.privoxy.conf
            fi

            rm "$FILE"
        fi
    done

    mv -f "${TMPDIR}/new.privoxy.conf" "/tmp/privoxy.conf"
}

# loop for options
while getopts ":hlqv" opt
do
    case "${opt}" in
        "h")
            usage
            exit 0
            ;;
        "v")
            DBG=2
            ;;
        "q")
            DBG=-1
            ;;
        "l")
            LOG=1
            ;;
    esac
done

startup
main

# If no file were downloaded at all, retry after 60 minutes...
if [ $ANY_DOWNLOAD = 0 ]; then
    debug "No file downloaded, retrying after 60 minutes..." 0
    (sleep 3600 && "$0") &
    shutdown 2
else
    debug "Finished." 0
    date +%s>"$LASTRUNFILE"
    shutdown 0
fi
