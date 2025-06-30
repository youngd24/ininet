#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <resolv.h>
#include <arpa/nameser.h>
#include <netinet/in.h>

#define BUF_SIZE 4096

void parse_txt_record(const char *txt, char *consvr, char *conport) {
    const char *start;
    const char *end;

    start = strstr(txt, "consvr=");
    if (start) {
        start += 7;
        end = strchr(start, ',');
        if (end && (end - start < 255)) {
            strncpy(consvr, start, end - start);
            consvr[end - start] = '\0';
        }
    }

    start = strstr(txt, "conport=");
    if (start) {
        start += 8;
        strncpy(conport, start, 31);
        conport[31] = '\0';
        end = strchr(conport, '"');
        if (end) *end = '\0';
    }
}

int main(int argc, char **argv) {
    unsigned char response[BUF_SIZE];
    ns_msg handle;
    ns_rr rr;
    int len, i, count;
    char consvr[256];
    char conport[32];

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <hostname>\n", argv[0]);
        return 1;
    }

    memset(consvr, 0, sizeof(consvr));
    memset(conport, 0, sizeof(conport));

    len = res_query(argv[1], ns_c_in, ns_t_txt, response, sizeof(response));
    if (len < 0) {
        perror("DNS query failed");
        return 1;
    }

    if (ns_initparse(response, len, &handle) < 0) {
        perror("ns_initparse");
        return 1;
    }

    count = ns_msg_count(handle, ns_s_an);

    for (i = 0; i < count; i++) {
        if (ns_parserr(&handle, ns_s_an, i, &rr) != 0) {
            continue;
        }

        const u_char *rdata = ns_rr_rdata(rr);
        int rdlen = ns_rr_rdlen(rr);
        int txtlen = rdata[0];

        if (txtlen >= rdlen || txtlen >= 255) continue;

        char txt[256];
        memset(txt, 0, sizeof(txt));
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
    {
        char *args[4];
        args[0] = "telnet";
        args[1] = consvr;
        args[2] = conport;
        args[3] = NULL;
        execvp("telnet", args);
        perror("execvp failed");
    }

    return 1;
}

