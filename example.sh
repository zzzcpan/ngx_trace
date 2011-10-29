#!/bin/sh

../ngx_trace/tracerx.pl -l -f 'core/ngx_conn|http/|event/|ngx_resol' \
			-i '_variable|_log_' ./objs/nginx -p example 
