<?php
if (!isset($_ENV['TRANSMART_USER'])) {
        fprintf(STDERR, "TRANSMART_USER is not set\n");
        exit(1);
}
$u = $_ENV['TRANSMART_USER'];
?>
#!/bin/bash

### BEGIN INIT INFO
# Provides:             rserve
# Required-Start:       $local_fs $remote_fs $network
# Required-Stop:        $local_fs $remote_fs $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    rserve
### END INIT INFO

NAME=Rserve
RSERVE_PID="/var/run/$NAME.pid"
RSERVE_LOG="/var/log/$NAME.log"

. /lib/lsb/init-functions

function do_start {
	set +e
	log_daemon_msg "Starting $NAME"
	if ! pgrep -u <?= $u ?> -f Rserve 
	then
		touch $RSERVE_PID $RSERVE_LOG
		chown <?= $u ?> $RSERVE_PID $RSERVE_LOG
		start-stop-daemon --start --chuid <?= $u ?>  -x /usr/bin/R CMD Rserve > $RSERVE_LOG 2>&1 
		EXIT_VAL=$?
        	if [ $EXIT_VAL -eq 0 ]; then
			pgrep -u <?= $u ?> -f Rserve > $RSERVE_PID
               	 	log_progress_msg "(Rserve started)"
			log_end_msg 0
        	else
                	log_progress_msg "(Failed starting)"
			log_end_msg 1
        	fi
	else
		log_progress_msg "(already running)"
		log_end_msg 0
	fi
	set -e

}

function do_stop {
	log_daemon_msg "Stopping $NAME"
        set +e

	if [ -f "$RSERVE_PID" ]; then
                start-stop-daemon --stop --pidfile "$RSERVE_PID" \
                        --user <?= $u ?> \
                        --retry=TERM/20/KILL/5 >/dev/null
                if [ $? -eq 1 ]; then
                        log_progress_msg "$NAME is not running but pid file exists, cleaning up"
                elif [ $? -eq 3 ]; then
                        PID="`cat $RSERVE_PID`"
                        log_failure_msg "Failed to stop $NAME (pid $PID)"
                        exit 1
                fi
                rm -f "$RSERVE_PID"
        else
                log_progress_msg "(not running)"
        fi
        log_end_msg 0
	set -e
}

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
             	set +e
		start-stop-daemon --test --start --pidfile "$RSERVE_PID" \
                	--user <?= $u ?> -- -c "/usr/bin/R CMD Rserve --vanilla" \
                	>/dev/null 2>&1
        	if [ "$?" = "0" ]; then

                	if [ -f "$RSERVE_PID" ]; then
                    		log_success_msg "$NAME is not running, but pid file exists."
                        	exit 1
                	else
                    		log_success_msg "$NAME is not running."
                        	exit 3
                	fi
        	else
                	log_success_msg "$NAME is running with pid `cat $RSERVE_PID`"
        	fi
        	set -e
        ;;

        *)
                echo "Usage: $0 {start|stop|status|restart|force-reload|reload}" >&2
                exit 1
        ;;
esac
