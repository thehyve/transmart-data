<?php
$r = "$_ENV[R_PREFIX]/bin/R";
?>

#!/bin/sh
### BEGIN INIT INFO
# Provides:             R/Rserve sysV service
# Required-Start:       $local_fs $remote_fs $network
# Required-Stop:        $local_fs $remote_fs $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Start/stop Rserve
# Author:               Leslie-Alexandre D. :]
### END INIT INFO

. /lib/lsb/init-functions

# conf

pid_file="/var/run/rserve.pid"

# user env

if [ -f /etc/default/rserve ]; then
        . /etc/default/rserve
fi
if [ -z "$USER" ]; then
        echo '$USER not defined' >&2
        exit 1
fi

# R env
r_path="$r"
r_pattern="/opt/R/lib/R/bin/Rserve"

# Rserve options
rserve_cmd="CMD Rserve --slave --vanilla --RS-conf /etc/Rserve.conf"
# functions

do_start() {
	rserve_status=$(pgrep -u "$USER" -cf "$r_pattern")
	if [ $rserve_status != 0 ]; then
		echo "Rserve is already running"
	else
       		echo "Rserve is starting..."
        	start-stop-daemon --start --quiet --oknodo --chuid $USER --exec $r_path -- $rserve_cmd
		get_pid
	fi
}

do_stop() {
        rserve_status=$(pgrep -u "$USER" -cf "$r_pattern")
	if [ $rserve_status != 0 ]; then
		kill `pgrep -u "$USER" -f "$r_pattern"` > /dev/null
		if [ $? = 0 ]; then
          		echo "Rserve is now stopped"
			if [ -f $pid_file ]; then rm $pid_file;fi;
        	else
          		echo "Rserve failed to stop"
        	fi
        else
		echo "Rserve is not running"
                exit 0
        fi
}

get_pid() {
	echo $(pgrep -u "$USER" -f "$r_pattern") > $pid_file
}

get_status() {
	if [ $(pgrep -u "$USER" -cf "$r_pattern") != 0 ] && [ -f $pid_file ]
        	then
                	echo "Rserve service running as PID: " $(tail $pid_file)
                        exit 0
                else
                        echo "Rserve is not running"
                        exit 1
                fi
}
# appel

case "$1" in
        start)
                do_start
        ;;

        stop)
                do_stop
        ;;

        restart|reload|force-reload)
                do_stop
                do_start
        ;;

        status)
		get_status
        ;;

        *)
                echo "Usage: $0 {start|stop|status|restart|force-reload|reload}" >&2
                exit 1
        ;;
esac

exit 0
