#!/usr/bin/bash

# Every source carries its own CLI because ReVanced (CLI v6 / patcher 22) and
# ReVanced-Extended (inotia00 CLI v5) are no longer compatible with each other.
# Everything about the current source is stored in "assets/$SOURCE/.data".

fetchAssetsInfo() {
    unset CLI_REPO CLI_VERSION CLI_URL CLI_SIZE PATCHES_VERSION PATCHES_URL PATCHES_SIZE JSON_URL
    local DATA_FILE PATCHES_REPO PATCHES_API JSON REMAINING

    internet || return 1

    DATA_FILE="assets/$SOURCE/.data"
    mkdir -p "assets/$SOURCE"
    rm -f "$DATA_FILE" "assets/.data" &> /dev/null

    source <(
        jq -r --arg SOURCE "$SOURCE" '
            .[] | select(.source == $SOURCE) |
            "CLI_REPO=\(.cli // "" | @sh)",
            "PATCHES_REPO=\(.patches.repository // "" | @sh)",
            "PATCHES_API=\(.patches.api // "" | @sh)",
            "JSON=\(.json // "" | @sh)"
        ' sources.json
    )

    if [ -z "$CLI_REPO" ]; then
        notify msg "Source \"$SOURCE\" is not available anymore.\nChange the source and try again."
        return 1
    fi

    REMAINING=$("${CURL[@]}" "https://api.github.com/rate_limit" | jq -r '.resources.core.remaining // 0' 2> /dev/null)
    if [ "${REMAINING:-0}" -le 2 ]; then
        notify msg "Unable to check for update.\nYou are probably rate-limited by GitHub at this moment.\nTry again later."
        return 1
    fi

    notify info "Fetching Assets Info..."

    {
        echo "CLI_REPO='$CLI_REPO'"
        "${CURL[@]}" "https://api.github.com/repos/$CLI_REPO/releases/latest" |
            jq -r '
                "CLI_VERSION=\(.tag_name | @sh)",
                (
                    [.assets[] | select(.name | endswith(".jar"))] |
                    (map(select(.name | endswith("-all.jar"))) + .)[0] // empty |
                    "CLI_URL=\(.browser_download_url | @sh)",
                    "CLI_SIZE=\(.size | tostring | @sh)"
                )
            ' 2> /dev/null
    } > "$DATA_FILE"

    source "$DATA_FILE"
    if [ -z "$CLI_VERSION" ] || [ -z "$CLI_URL" ]; then
        rm -f "$DATA_FILE"
        notify msg "Unable to fetch latest CLI info from API!!\nRetry later."
        return 1
    fi

    if [ -n "$PATCHES_API" ]; then
        # ReVanced patches are no longer on GitHub; the official API serves them.
        "${CURL[@]}" "$PATCHES_API" |
            jq -r '
                "PATCHES_VERSION=\(.version | @sh)",
                "PATCHES_URL=\(.download_url | @sh)",
                "PATCHES_SIZE='\'''\''"
            ' >> "$DATA_FILE" 2> /dev/null
    else
        "${CURL[@]}" "https://api.github.com/repos/$PATCHES_REPO/releases/latest" |
            jq -r '
                "PATCHES_VERSION=\(.tag_name | @sh)",
                (
                    .assets[] |
                    select(.name | endswith(".rvp")) |
                    "PATCHES_URL=\(.browser_download_url | @sh)",
                    "PATCHES_SIZE=\(.size | tostring | @sh)"
                )
            ' >> "$DATA_FILE" 2> /dev/null
    fi

    source "$DATA_FILE"
    if [ -z "$PATCHES_VERSION" ] || [ "$PATCHES_VERSION" == "null" ] || [ -z "$PATCHES_URL" ]; then
        rm -f "$DATA_FILE"
        notify msg "Unable to fetch latest Patches info from API!!\nRetry later."
        return 1
    fi

    [ -n "$JSON" ] && setEnv JSON_URL "$JSON" init "$DATA_FILE"
    source "$DATA_FILE"
}

# Returns 0 if FILE is a complete download.
# When the server doesn't publish a size, the file is checked as a zip archive.
isAssetValid() {
    local FILE="$1" SIZE="$2"
    [ -s "$FILE" ] || return 1
    if [ -n "$SIZE" ]; then
        [ "$SIZE" == "$(stat -c %s "$FILE" 2> /dev/null || echo 0)" ]
    else
        unzip -tqq "$FILE" &> /dev/null
    fi
}

# downloadAsset LABEL URL SIZE FILE
downloadAsset() {
    local LABEL="$1" URL="$2" SIZE="$3" FILE="$4" CTR SIZE_TEXT

    if [ -n "$SIZE" ]; then
        SIZE_TEXT=$(numfmt --to=iec --format="%0.1f" "$SIZE")
    else
        SIZE_TEXT="Unknown"
    fi

    CTR=2 && until isAssetValid "$FILE" "$SIZE"; do
        if [ $CTR -eq 0 ]; then
            rm -f "$FILE" &> /dev/null
            notify msg "Oops! Unable to download $LABEL completely.\n\nRetry or change your Network."
            return 1
        fi
        ((CTR--))
        # Resuming is only safe when we know the expected size.
        [ -z "$SIZE" ] && rm -f "$FILE" &> /dev/null
        "${WGET[@]}" "$URL" -O "$FILE" |&
            stdbuf -o0 cut -b 63-65 |
            stdbuf -o0 grep '[0-9]' |
            "${DIALOG[@]}" --gauge "File    : $LABEL\nSize    : $SIZE_TEXT\n\nDownloading..." -1 -1 \
                "$(if [ -n "$SIZE" ]; then echo $((($(stat -c %s "$FILE" 2> /dev/null || echo 0) * 100) / SIZE)); else echo 0; fi)"
        tput civis
    done
}

fetchAssets() {
    local DATA_FILE="assets/$SOURCE/.data"

    # Never reuse the previous source's CLI or patches info.
    unset CLI_REPO CLI_VERSION CLI_URL CLI_SIZE PATCHES_VERSION PATCHES_URL PATCHES_SIZE JSON_URL
    if [ -e "$DATA_FILE" ]; then
        source "$DATA_FILE"
    fi
    if [ -z "$CLI_REPO" ] || [ -z "$CLI_VERSION" ] || [ -z "$PATCHES_VERSION" ]; then
        fetchAssetsInfo || return 1
    fi

    CLI_MAJOR=$(sed -E 's/^v?([0-9]+).*/\1/' <<< "$CLI_VERSION")
    [[ "$CLI_MAJOR" =~ ^[0-9]+$ ]] || CLI_MAJOR=0

    rm -f -- assets/CLI-*.jar &> /dev/null # layout used before v3
    CLI_FILE="assets/CLI/${CLI_REPO%%/*}-$CLI_VERSION.jar"
    mkdir -p "assets/CLI"
    if [ ! -e "$CLI_FILE" ]; then
        rm -f -- "assets/CLI/${CLI_REPO%%/*}-"*.jar &> /dev/null
    fi
    downloadAsset "CLI-$CLI_VERSION.jar" "$CLI_URL" "$CLI_SIZE" "$CLI_FILE" || return 1

    PATCHES_FILE="assets/$SOURCE/Patches-$PATCHES_VERSION.rvp"
    if [ ! -e "$PATCHES_FILE" ]; then
        rm -f -- "assets/$SOURCE/Patches-"* &> /dev/null
    fi
    downloadAsset "Patches-$PATCHES_VERSION.rvp" "$PATCHES_URL" "$PATCHES_SIZE" "$PATCHES_FILE" || return 1

    # Remember the real size so the zip test doesn't run on every launch.
    if [ -z "$PATCHES_SIZE" ]; then
        PATCHES_SIZE=$(stat -c %s "$PATCHES_FILE")
        setEnv PATCHES_SIZE "$PATCHES_SIZE" update "$DATA_FILE"
    fi

    parsePatchesJson || return 1
}

# CLI v6+ requires every patches file to be either verified or explicitly bypassed.
patchesFileArgs() {
    if [ "${CLI_MAJOR:-0}" -ge 6 ]; then
        PATCHES_ARGS=(--patches="$PATCHES_FILE" --bypass-verification)
    else
        PATCHES_ARGS=(--patches="$PATCHES_FILE")
    fi
}

deleteAssets() {
    if "${DIALOG[@]}" \
        --title '| Delete Assets |' \
        --defaultno \
        --yesno "Please confirm to delete the assets.\nIt will delete the CLI and patches." -1 -1 \
        ; then
        unset CLI_REPO CLI_VERSION CLI_URL CLI_SIZE PATCHES_VERSION PATCHES_URL PATCHES_SIZE JSON_URL
        rm -rf assets &> /dev/null
        mkdir assets
    fi
}
