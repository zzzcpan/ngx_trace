
#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>

static ngx_http_module_t  ngx_http_ptrace_ctx = {
    NULL,                                  /* preconfiguration */
    NULL,                                  /* postconfiguration */

    NULL,                                  /* create main configuration */
    NULL,                                  /* init main configuration */

    NULL,                                  /* create server configuration */
    NULL,                                  /* merge server configuration */

    NULL,                                  /* create location configuration */
    NULL                                   /* merge location configuration */
};

ngx_module_t  ngx_http_ptrace = {
    NGX_MODULE_V1,
    &ngx_http_ptrace_ctx,                  /* module context */
    NULL,                                  /* module directives */
    NGX_HTTP_MODULE,                       /* module type */
    NULL,                                  /* init master */
    NULL,                                  /* init module */
    NULL,                                  /* init process */
    NULL,                                  /* init thread */
    NULL,                                  /* exit thread */
    NULL,                                  /* exit process */
    NULL,                                  /* exit master */
    NGX_MODULE_V1_PADDING
};


int notrace;

void __cyg_profile_func_enter(void *this_fn, void *call_site)
	__attribute__ ((no_instrument_function));
void __cyg_profile_func_exit(void *this_fn, void *call_site)
	__attribute__ ((no_instrument_function));

void ngx_cdecl
ngx_trace(const char *fmt, ...)
	__attribute__ ((no_instrument_function));



void ngx_cdecl
ngx_trace(const char *fmt, ...)
{
    u_char   *p, *last;
    va_list   args;
    u_char    errstr[NGX_MAX_ERROR_STR];

    last = errstr + NGX_MAX_ERROR_STR;
    p = errstr + 7;

    ngx_memcpy(errstr, "nginx: ", 7);

    va_start(args, fmt);
    p = ngx_vslprintf(p, last, fmt, args);
    va_end(args);

    if (p > last - NGX_LINEFEED_SIZE) {
        p = last - NGX_LINEFEED_SIZE;
    }

    ngx_linefeed(p);

    (void) ngx_write_console(1, errstr, p - errstr);
}




void
__cyg_profile_func_enter(void *this_fn, void *call_site)
{
    if (notrace) return;
    
    notrace = 1;
    ngx_trace("enter %p", this_fn);
    notrace = 0;

    (void)call_site;
}

void
__cyg_profile_func_exit(void *this_fn, void *call_site)
{
    if (notrace) return;

    notrace = 1;
    ngx_trace("exit %p", this_fn);
    notrace = 0;

    (void)call_site;
}


