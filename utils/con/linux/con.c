/******************************************************************************
 *
 * con.c
 *
 * 
 *
 *****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <resolv.h>
#include <arpa/nameser.h>
#include <netinet/in.h>
#include <unistd.h>

#define BUF_SIZE 4096

void parse_txt_record(const char *txt, char *consvr, char *conport) {
    const char *start;
    if ((start = strstr(txt, "consvr=")) != NULL) {
        start += 7;
        const char *end = strchr(start, ',');
        if (end) {
            strncpy(consvr, start, end - start);
            consvr[end - start] = '\0';
        }
    }

    if ((start = strstr(txt, "conport=")) != NULL) {
        start += 8;
        strncpy(conport, start, 31);
        conport[30] = '\0';
        char *newline = strchr(conport, '"');
        if (newline) *newline = '\0';
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <hostname>\n", argv[0]);
        return 1;
    }

    unsigned char response[BUF_SIZE];
    ns_msg handle;
    ns_rr rr;
    int len;

    len = res_query(argv[1], ns_c_in, ns_t_txt, response, sizeof(response));
    if (len < 0) {
        perror("DNS query failed");
        return 1;
    }

    if (ns_initparse(response, len, &handle) < 0) {
        perror("ns_initparse");
        return 1;
    }

    int count = ns_msg_count(handle, ns_s_an);
    char consvr[256] = {0};
    char conport[32] = {0};

    for (int i = 0; i < count; i++) {
        if (ns_parserr(&handle, ns_s_an, i, &rr) != 0) {
            continue;
        }

        const u_char *rdata = ns_rr_rdata(rr);
        int rdlen = ns_rr_rdlen(rr);
        int txtlen = rdata[0];

        if (txtlen >= rdlen) continue;

        char txt[256] = {0};
        memcpy(txt, rdata + 1, txtlen);
        txt[txtlen] = '\0';

        if (strstr(txt, "consvr=") && strstr(txt, "conport=")) {
            parse_txt_record(txt, consvr, conport);
            break;
        }
    }

    if (consvr[0] == '\0' || conport[0] == '\0') {
        fprintf(stderr, "Valid TXT record with consvr and conport not found.\n");
        return 1;
    }

    printf("Connecting to %s on port %s using telnet...\n", consvr, conport);
    char *args[] = { "telnet", consvr, conport, NULL };
    execvp("telnet", args);

    perror("execvp failed");
    return 1;
}

