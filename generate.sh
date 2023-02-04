#!/usr/bin/env bash

### Helpers begin
check_deps() {
    local missing
    for d in "${deps[@]}"; do
        if [[ -z $(command -v "$d") ]]; then
            # Force absolute path
            if [[ ! -e "/$d" ]]; then
                err "$d was not found"
                missing="true"
            fi
        fi
    done; unset d
    [[ -z $missing ]] || exit 128
}
err() { echo -e "${color:+\e[31m}[!] $*${color:+\e[0m}" >&2; }
errx() { err "${*:2}"; exit "$1"; }
good() { echo -e "${color:+\e[32m}[+] $*${color:+\e[0m}"; }
info() { echo -e "${color:+\e[37m}[*] $*${color:+\e[0m}"; }
long_opt() {
    local arg shift="0"
    case "$1" in
        "--"*"="*) arg="${1#*=}"; [[ -n $arg ]] || return 127 ;;
        *) shift="1"; shift; [[ $# -gt 0 ]] || return 127; arg="$1" ;;
    esac
    echo "$arg"
    return "$shift"
}
subinfo() { echo -e "${color:+\e[36m}[=] $*${color:+\e[0m}"; }
warn() { echo -e "${color:+\e[33m}[-] $*${color:+\e[0m}"; }
### Helpers end

usage() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS]

DESCRIPTION
    Generate index.html.

OPTIONS
    -h, --help        Display this help message
        --no-color    Disable colorized output

EOF
    exit "$1"
}

declare -a args
unset help
color="true"
file="index.html"
jq="jq -c -M -r -S"

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        "--") shift; args+=("$@"); break ;;
        "-h"|"--help") help="true" ;;
        "--no-color") unset color ;;
        *) args+=("$1") ;;
    esac
    case "$?" in
        0) ;;
        1) shift ;;
        *) usage "$?" ;;
    esac
    shift
done
[[ ${#args[@]} -eq 0 ]] || set -- "${args[@]}"

# Help info
[[ -z $help ]] || usage 0

# Check for missing dependencies
declare -a deps
deps+=("jq")
check_deps

# Check for valid params
[[ $# -eq 0 ]] || usage 1
[[ -f projs.json ]] || errx 2 "projs.json not found"

cat >"$file" <<EOF
<!doctype html>
<html>
  <head>
    <base target="_parent">
    <link href="assets/css/normalize.css" rel="stylesheet" type="text/css">
    <link href="assets/css/main.css" rel="stylesheet" type="text/css">
    <meta charset="utf-8">
    <meta content="chrome=1" http-equiv="X-UA-Compatible">
    <meta content="width=device-width, initial-scale=1, user-scalable=no" name="viewport">
    <script src="assets/js/jquery1.7.1.min.js" type="text/javascript"></script>
    <title>Miles Whittaker</title>
  </head>
  <body>
    <div id="scroll-animate">
      <div id="scroll-animate-main">
        <div class="wrapper-parallax">
          <header>
            <h1><br>Arch Nemesis</h1>
          </header>
          <section class="content">
            <br>
            <h1>
              <span class="keyword1">package</span> mjwhitta<br>
              <br>
              <span class="keyword1">type</span> Me <span class="keyword1">struct</span> {<br>
              &nbsp;&nbsp;<span class="comment">// Posts []Post // Someday</span><br>
              &nbsp;&nbsp;Projs []Proj<br>
              }<br>
              <br>
              <span class="keyword1">type</span> Proj <span class="keyword1">struct</span> {<br>
              &nbsp;&nbsp;Desc <span class="keyword2">string</span><br>
              &nbsp;&nbsp;Get&nbsp; <span class="keyword2">string</span><br>
              &nbsp;&nbsp;Name <span class="keyword2">string</span><br>
              }<br>
              <br>
              <span class="keyword1">var</span> mjwhitta = Me{<br>
              &nbsp;&nbsp;Projs: []Proj{<br>
EOF

while read -r line; do
    unset comment desc get img name

    comment="$($jq ".comment" <<<"$line")"
    case "$comment" in
        ""|"null") ;;
        *)
            info "Comment: $comment"
            cat >>"$file" <<EOF
              &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">// $comment</span><br>
EOF
            continue
            ;;
    esac

    desc="$($jq ".desc" <<<"$line")"
    get="$($jq ".get" <<<"$line")"
    img="$($jq ".img" <<<"$line")"
    name="$($jq ".name" <<<"$line")"

    case "$img" in
        ""|"null") ;;
        *)
            subinfo "Adding image for $name"
            cat >>"$file" <<EOF
              <table>
                <tr>
                  <td>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                    &nbsp;&nbsp;&nbsp;&nbsp;<span class="comment">//</span><br>
                  </td>
                  <td>
                    &nbsp;<img src="$img" width="512px"/>
                  </td>
                </tr>
              </table>
EOF
            ;;
    esac

    good "Adding $name"
    cat >>"$file" <<EOF
              &nbsp;&nbsp;&nbsp;&nbsp;{<br>
              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Desc:
              <span class="string">"$desc"</span>,<br>
              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Get:&nbsp;
              <span class="string">"$get"</span>,<br>
              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Name:
              <a class="string" href="https://github.com/mjwhitta/${name,,}">"$name"</a>,<br>
              &nbsp;&nbsp;&nbsp;&nbsp;},<br>
EOF
done < <($jq ".[]" projs.json); unset line

cat >>"$file" <<EOF
              &nbsp;&nbsp;},<br>
              }<br>
              <br>
          </section>
          <footer>
              <h1>
                <br>E:&nbsp;mj[@]whitta[.]dev | GitHub:&nbsp;<a class="link" href="https://github.com/mjwhitta">mjwhitta</a><br>
                <a class="link" href="https://www.credential.net/8d5c7efa-5a47-42aa-9917-f35e00f78750">CRTP (expired)</a>
                |
                <a class="link" href="https://www.offensive-security.com/ctp-osce">OSCE</a>
                |
                <a class="link" href="https://www.offensive-security.com/courses/pen-200">OSCP</a>
                |
                <a class="link" href="https://www.offensive-security.com/courses/pen-210">OSWP</a>
                |
                <a class="link" href="https://www.cisco.com/c/en/us/training-events/training-certifications/certifications/associate/ccna.html">CCNA (expired)</a>
              </h1>
          </footer>
        </div>
      </div>
    </div>
    <script src="assets/js/main.js" type="text/javascript"></script>
  </body>
</html>
EOF
