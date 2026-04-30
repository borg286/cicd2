# Make a sha of the contents of the templates directory
STABLE_CHART_VERSION = sha1sum(templates/*)

# Get a semver that includes today's date down to the hour
VOLATILE_BUILD_TIME = date +"%Y.%m.%d.%H"

echo "STABLE_CHART_VERSION $STABLE_CHART_VERSION"
echo "VOLATILE_BUILD_TIME $VOLATILE_BUILD_TIME"