#!/usr/bin/env bash
# Publish the already verified raw ISO and checksum to a GitHub Release.
set -Eeuo pipefail

: "${RELEASE_MODE:?Set RELEASE_MODE to rolling or versioned}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${ISO_PATH:?ISO_PATH must name the built ISO}"
: "${CHECKSUM_PATH:?CHECKSUM_PATH must name the ISO checksum}"
: "${RELEASE_NOTES_PATH:?RELEASE_NOTES_PATH is required}"

[[ -f $ISO_PATH && -s $ISO_PATH ]] || { printf 'ISO is missing or empty: %s\n' "$ISO_PATH" >&2; exit 1; }
[[ -f $CHECKSUM_PATH && -s $CHECKSUM_PATH ]] || { printf 'Checksum is missing or empty: %s\n' "$CHECKSUM_PATH" >&2; exit 1; }
[[ -f $RELEASE_NOTES_PATH ]] || { printf 'Release notes are missing: %s\n' "$RELEASE_NOTES_PATH" >&2; exit 1; }

iso_name=$(basename -- "$ISO_PATH")
checksum_name=$(basename -- "$CHECKSUM_PATH")
[[ $iso_name =~ ^kairo-arch-[A-Za-z0-9._-]+\.iso$ ]] || {
    printf 'Unexpected ISO filename: %s\n' "$iso_name" >&2
    exit 1
}
[[ $checksum_name == "$iso_name.sha256" ]] || {
    printf 'Checksum must be named %s.sha256\n' "$iso_name" >&2
    exit 1
}

# GitHub rejects release assets at or above 2 GiB. Fail before editing a release;
# never split, compress, or substitute an artifact for the raw ISO.
max_asset_bytes=$((2 * 1024 * 1024 * 1024))
iso_bytes=$(stat -c '%s' -- "$ISO_PATH")
if ((iso_bytes >= max_asset_bytes)); then
    printf 'ISO is %s bytes; GitHub Release assets must be smaller than 2 GiB. No release was changed.\n' "$iso_bytes" >&2
    exit 1
fi

case $RELEASE_MODE in
    rolling)
        tag=rolling
        title='Kairo Rolling ISO'
        ;;
    versioned)
        : "${RELEASE_TAG:?Set RELEASE_TAG for a versioned release}"
        [[ $RELEASE_TAG == iso-v* ]] || { printf 'Refusing unexpected versioned tag: %s\n' "$RELEASE_TAG" >&2; exit 1; }
        tag=$RELEASE_TAG
        title="Kairo ISO $tag"
        ;;
    *)
        printf 'Unsupported RELEASE_MODE: %s\n' "$RELEASE_MODE" >&2
        exit 2
        ;;
esac

wait_for_prior_main_releases() {
    [[ $RELEASE_MODE == rolling && ${GITHUB_REF:-} == refs/heads/main ]] || return 0
    : "${GITHUB_RUN_NUMBER:?GITHUB_RUN_NUMBER is required for serialized rolling publication}"
    [[ $GITHUB_RUN_NUMBER =~ ^[0-9]+$ ]] || { printf 'Invalid GitHub run number.\n' >&2; return 1; }

    local pending
    while true; do
        filter=$(printf '.workflow_runs[] | select(.head_branch == "main" and (.event == "push" or .event == "workflow_dispatch") and .run_number < %s and .status != "completed") | .run_number' "$GITHUB_RUN_NUMBER")
        pending=$(gh api --paginate \
            "repos/$GITHUB_REPOSITORY/actions/workflows/build-iso.yml/runs?branch=main&per_page=100" \
            --jq "$filter")
        [[ -z $pending ]] && break
        printf 'Waiting for earlier main ISO run(s) to finish before updating the rolling release: %s\n' "${pending//$'\n'/, }"
        sleep 15
    done
}

wait_for_prior_main_releases

if gh release view "$tag" >/dev/null 2>&1; then
    release_exists=true
else
    release_exists=false
fi

if $release_exists; then
    gh release upload "$tag" "$ISO_PATH" "$CHECKSUM_PATH" --clobber
else
    if [[ $RELEASE_MODE == rolling ]]; then
        ref_url="repos/$GITHUB_REPOSITORY/git/ref/tags/$tag"
        if gh api "$ref_url" >/dev/null 2>&1; then
            gh api --method PATCH "repos/$GITHUB_REPOSITORY/git/refs/tags/$tag" \
                -f "sha=$GITHUB_SHA" \
                -F force=true
        else
            gh api --method POST "repos/$GITHUB_REPOSITORY/git/refs" \
                -f "ref=refs/tags/$tag" \
                -f "sha=$GITHUB_SHA"
        fi
    fi

    create_args=(
        gh release create "$tag"
        "$ISO_PATH"
        "$CHECKSUM_PATH"
        --target "$GITHUB_SHA"
        --title "$title"
        --notes-file "$RELEASE_NOTES_PATH"
        --verify-tag
    )
    if [[ $RELEASE_MODE == rolling ]]; then
        create_args+=(--latest=false)
    fi
    "${create_args[@]}"
fi

if [[ $RELEASE_MODE == rolling ]]; then
    release_id=$(gh api "repos/$GITHUB_REPOSITORY/releases/tags/$tag" --jq '.id')
    [[ $release_id =~ ^[0-9]+$ ]] || { printf 'Could not find release ID for %s\n' "$tag" >&2; exit 1; }
    assets_url="repos/$GITHUB_REPOSITORY/releases/$release_id/assets"
    assets=$(gh api --paginate "$assets_url" --jq '.[] | [.id, .name, (.size | tostring)] | @tsv')

    iso_count=0
    checksum_count=0
    while IFS=$'\t' read -r asset_id asset_name asset_size; do
        [[ -n $asset_id ]] || continue
        if [[ $asset_name == "$iso_name" ]]; then
            ((asset_size == iso_bytes)) || { printf 'Uploaded ISO asset size does not match the build.\n' >&2; exit 1; }
            ((iso_count += 1))
        elif [[ $asset_name == "$checksum_name" ]]; then
            expected_checksum_size=$(stat -c '%s' -- "$CHECKSUM_PATH")
            ((asset_size == expected_checksum_size)) || { printf 'Uploaded checksum asset size does not match the build.\n' >&2; exit 1; }
            ((checksum_count += 1))
        else
            printf 'Removing outdated rolling release asset: %s\n' "$asset_name"
            gh api --method DELETE "repos/$GITHUB_REPOSITORY/releases/$release_id/assets/$asset_id"
        fi
    done <<< "$assets"
    ((iso_count == 1 && checksum_count == 1)) || {
        printf 'Rolling release does not contain exactly the current ISO and checksum (found ISO=%s checksum=%s).\n' "$iso_count" "$checksum_count" >&2
        exit 1
    }
    gh release edit "$tag" \
        --title "$title" \
        --notes-file "$RELEASE_NOTES_PATH" \
        --draft=false \
        --latest=false
    gh api --method PATCH "repos/$GITHUB_REPOSITORY/git/refs/tags/$tag" \
        -f "sha=$GITHUB_SHA" \
        -F force=true
else
    gh release edit "$tag" \
        --title "$title" \
        --notes-file "$RELEASE_NOTES_PATH" \
        --draft=false
fi

printf 'Published %s and %s to release %s.\n' "$iso_name" "$checksum_name" "$tag"
