#!/bin/sh

usage() {
  printf "Usage: ./bump_version.sh [-p|-m|-M]\n" 1>&2
  printf "  -p   bump patch (e.g., 1.1.4 -> 1.1.5)\n" 1>&2
  printf "  -m   bump minor (e.g., 1.1.4 -> 1.2.0)\n" 1>&2
  printf "  -M   bump major (e.g., 1.1.4 -> 2.0.0)\n" 1>&2
}

# Parse options.
p=""
m=""
M=""
while getopts 'hpmM' 'OPTION'; do
  case "$OPTION" in
    h)
      usage
      exit 0
      ;;
    p)
      p="true"
      ;;
    m)
      m="true"
      ;;
    M)
      M="true"
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

# Get most recent tag, in parts/
read -r major minor patch <<<`git describe --abbrev=0 | tr '.' ' '`;

# Bump.
if [ "$M" == "true" ]; then
  major=`expr $major + 1`
  minor="0"
  patch="0"
else
  if [ "$m" == "true" ]; then
    minor=`expr $minor + 1`
    patch="0"
  else
    if [ "$p" == "true" ]; then
      patch=`expr $patch + 1`
    else
      usage
      exit 2
    fi
  fi
fi

new_version="$major.$minor.$patch"

printf "\nWriting git annotated tag at version: $new_version\n\n"
git tag -a "$new_version" -m "$new_version"
printf "Don't forget to push tags by adding --follow-tags to your push command, like:\n\n"
printf "    git push origin master --follow-tags\n\n"
