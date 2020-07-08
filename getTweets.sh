#!/usr/bin/env bash
#
# Fetch tweets from a specific user
#
#/ Usage:
#/   ./getTweets.sh -u <twitter_handle> [-m <max_num>] [-d]
#/
#/ Options:
#/   -u <handle>        Mandatory, set twitter handle
#/   -d                 Optional, direct output without saving to json file
#/   -m                 Optional, max tweets number to download
#/   -h | --help        Display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    _CURL=$(command -v curl)
    _JQ=$(command -v jq)

    _HOST_URL="https://twitter.com"
    _API_URL="https://api.twitter.com"
    [[ -z "${_MAX_TWEETS:-}" ]] && _MAX_TWEETS="4000" # API limit ~3200
    _AUTH_TOKEN="AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

    _TIMESTAMP="$(date +%s)"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":hdm:u:" opt; do
        case $opt in
            u)
                _USER_HANDLE="$OPTARG"
                ;;
            d)
                _DIRECT_OUTPUT=true
                ;;
            m)
                _MAX_TWEETS="$OPTARG"
                ;;
            h)
                usage
                ;;
            \?)
                echo "[ERROR] Invalid option: -$OPTARG" >&2
                usage
                ;;
        esac
    done
}

check_var() {
    if [[ -z "${_USER_HANDLE:-}" ]]; then
        echo "[ERROR] Missing twitter handle!" & usage
    fi
}

fetch_guest_token() {
    # $1: twitter handle
    $_CURL -sS "$_HOST_URL/$1" \
        -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:75.0) Gecko/20100101 Firefox/73.0' \
        | grep 'decodeURIComponent("gt=' \
        | sed -E 's/.*gt=//' \
        | awk -F ';' '{print $1}'
}

get_user_id() {
    # $1: twitter handle
    # $2: auth token
    $_CURL -sS "$_API_URL/graphql/P8ph10GzBbdMqWZxulqCfA/UserByScreenName?variables=%7B%22screen_name%22%3A%22$1%22%2C%22withHighlightedLabel%22%3Atrue%7D" \
        --header "authorization: Bearer $2" \
        | $_JQ -r '.data.user.rest_id'
}

fetch_tweets() {
    # $1: user id
    # $2: auth token
    # $3: guest token
    $_CURL -sS "$_API_URL/2/timeline/profile/$1.json?include_profile_interstitial_type=1&include_blocking=1&include_blocked_by=1&include_followed_by=1&include_want_retweets=1&include_mute_edge=1&include_can_dm=1&include_can_media_tag=1&skip_status=1&cards_platform=Web-12&include_cards=1&include_composer_source=true&include_ext_alt_text=true&include_reply_count=1&tweet_mode=extended&include_entities=true&include_user_entities=true&include_ext_media_color=true&include_ext_media_availability=true&send_error_codes=true&simple_quoted_tweets=true&include_tweet_replies=true&count=$_MAX_TWEETS&ext=mediaStats%2ChighlightedLabel%2CcameraMoment" \
        --header "authorization: Bearer $2" \
        --header "x-guest-token: $3" \
        | $_JQ '.globalObjects.tweets | .[] | select(.user_id_str==$id)' --arg id "$1" \
        | $_JQ -s 'sort_by(.id_str)'
}

main() {
    set_args "$@"
    set_var
    check_var

    local i t

    i=$(get_user_id "$_USER_HANDLE" "$_AUTH_TOKEN")
    t=$(fetch_guest_token "$_USER_HANDLE")

    if [[ -z "${_DIRECT_OUTPUT:-}" ]]; then
        fetch_tweets "$i" "$_AUTH_TOKEN" "$t" > "${_USER_HANDLE}_${_TIMESTAMP}.json"
    else
        fetch_tweets "$i" "$_AUTH_TOKEN" "$t"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
