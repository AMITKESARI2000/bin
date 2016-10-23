#!/usr/bin/env bash
#
# Originally written by Sam Stephenson for xip.io
set -e
shopt -s nocasematch

# Configuration
#
# Increment this timestamp when the contents of the file change.
XIP_TIMESTAMP="2016102202"

# The top-level domain for which the name server is authoritative.
# CHANGEME: change "sslip.io" to your domain
XIP_DOMAIN="sslip.io"

# How long responses should be cached, in seconds.
XIP_TTL=300

# SOA record
XIP_SOA="briancunnie.gmail.com ns-he.nono.io $XIP_TIMESTAMP $XIP_TTL $XIP_TTL $XIP_TTL $XIP_TTL"

# The public IP addresses (e.g. for the web site) of the top-level domain.
# `A` queries for the top-level domain will return this list of addresses.
# CHANGEME: change this to your domain's webserver's address
XIP_ROOT_ADDRESSES=( "52.0.56.137" )

# The public IP addresses on which this xip-pdns server will run.
# `NS` queries for the top-level domain will return this list of addresses.
# Each entry maps to a 1-based subdomain of the format `ns-1`, `ns-2`, etc.
# `A` queries for these subdomains map to the corresponding addresses here.
# CHANGEME: change this to match your NS records; one of these IP addresses
# should match the jobs(xip).networks.static_ips listed above
XIP_NS_ADDRESSES=( "52.0.56.137"    "52.187.42.158"    "104.155.144.4"  "78.47.249.19" )
XIP_NS=(           "ns-aws.nono.io" "ns-azure.nono.io" "ns-gce.nono.io" "ns-he.nono.io" )

# These are the MX records for your domain.  IF YOU'RE NOT SURE,
# don't set it at at all (comment it out)--it defaults to no
# MX records.
# XIP_MX_RECORDS=(
#   "10"  "mx.zoho.com"
#   "20"  "mx2.zoho.com"
# )
XIP_MX_RECORDS=( )

if [ -a "$1" ]; then
  source "$1"
fi

#
# Protocol helpers
#
read_cmd() {
  local IFS=$'\t'
  local i=0
  local arg

  read -ra CMD
  for arg; do
    eval "$arg=\"\${CMD[$i]}\""
    let i=i+1
  done
}

send_cmd() {
  local IFS=$'\t'
  printf "%s\n" "$*"
}

fail() {
  send_cmd "FAIL"
  log "Exiting"
  exit 1
}

read_helo() {
  read_cmd HELO VERSION
  [ "$HELO" = "HELO" ] && [ "$VERSION" = "1" ]
}

read_query() {
  read_cmd TYPE QNAME QCLASS QTYPE ID IP
}

send_answer() {
  local type="$1"
  shift
  send_cmd "DATA" "$QNAME" "$QCLASS" "$type" "$XIP_TTL" "$ID" "$@"
}

log() {
  printf "[xip-pdns:$$] %s\n" "$@" >&2
}


#
# xip.io domain helpers
#
IP_PATTERN="(^|\.)(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))($|\.)"
DASHED_IP_PATTERN="(^|-|\.)(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))($|-|\.)"

qtype_is() {
  [ "$QTYPE" = "$1" ] || [ "$QTYPE" = "ANY" ]
}

qname_is_root_domain() {
  [ "$QNAME" = "$XIP_DOMAIN" ]
}

subdomain_is_ip() {
  [[ "$QNAME" =~ $IP_PATTERN ]]
}

subdomain_is_dashed_ip() {
  [[ "$QNAME" =~ $DASHED_IP_PATTERN ]]
}

resolve_ns_subdomain() {
  local index="${SUBDOMAIN:3}"
  echo "${XIP_NS_ADDRESSES[$index-1]}"
}

resolve_ip_subdomain() {
  [[ "$QNAME" =~ $IP_PATTERN ]] || true
  echo "${BASH_REMATCH[2]}"
}

resolve_dashed_ip_subdomain() {
  [[ "$QNAME" =~ $DASHED_IP_PATTERN ]] || true
  echo "${BASH_REMATCH[2]//-/.}"
}

answer_soa_query() {
  send_answer "SOA" "$XIP_SOA"
}

answer_ns_query() {
  local i=1
  local ns_address
  for ns in "${XIP_NS[@]}"; do
    send_answer "NS" "$ns"
  done
}

answer_root_a_query() {
  local address
  for address in "${XIP_ROOT_ADDRESSES[@]}"; do
    send_answer "A" "$address"
  done
}

answer_mx_query() {
  set -- "${XIP_MX_RECORDS[@]}"
  while [ $# -gt 1 ]; do
    send_answer "MX" "$1	$2"
  shift 2
  done
}

answer_subdomain_a_query_for() {
  local type="$1"
  local address="$(resolve_${type}_subdomain)"
  if [ -n "$address" ]; then
    send_answer "A" "$address"
  fi
}


#
# PowerDNS pipe backend implementation
#
trap fail err
read_helo
send_cmd "OK" "xip.io PowerDNS pipe backend (protocol version 1)"

while read_query; do
  log "Query: type=$TYPE qname=$QNAME qclass=$QCLASS qtype=$QTYPE id=$ID ip=$IP"

  if qtype_is "SOA"; then
    answer_soa_query
  fi
  if qtype_is "NS"; then
    answer_ns_query
  fi
  if qtype_is "MX"; then
    answer_mx_query
  fi
  if qtype_is "A"; then
    if [ $QNAME == $XIP_DOMAIN ]; then
      answer_root_a_query
    else
      if subdomain_is_dashed_ip; then
        answer_subdomain_a_query_for dashed_ip
      elif subdomain_is_ip; then
        answer_subdomain_a_query_for ip
      fi
    fi
  fi

  send_cmd "END"
done
