#!/bin/sh

set -eu;

script_dir=$(dirname "${0}");
base_dir=$(realpath "${script_dir}/..");
public_dir="${base_dir}/public";
summary_dir="${base_dir}/summary";

echo "Building summary pages using Asciidoctor Jet...";

# Create required directories if they don't exist
mkdir -p "${public_dir}/css/summary";
mkdir -p "${public_dir}/html/summary";
mkdir -p "${public_dir}/js/summary";
mkdir -p "${public_dir}/img/summary";

# Remove all summary files to prevent residual files
rm -rf "${public_dir}/css/summary/"*;
rm -rf "${public_dir}/html/summary/"*;
rm -rf "${public_dir}/js/summary/"*;
rm -rf "${public_dir}/img/summary/"*;
rm -f "${summary_dir}/autogenerated-combined-summary.adoc";

# Copy files to public directory for static serving
cp -r "${summary_dir}/static/css/"* "${public_dir}/css/summary";
cp -r "${summary_dir}/static/js/"* "${public_dir}/js/summary";
cp -r "${summary_dir}/static/img/"* "${public_dir}/img/summary";

# Reverse order so summaries are newest to oldest
BUILD_SUMMARY_DIRS="";
for path in "${summary_dir}/sessions/"*; do
	if [ -d "${path}" ]; then
		BUILD_SUMMARY_DIRS="${path} ${BUILD_SUMMARY_DIRS}";
	fi;
done;

# Build individual summary pages
for path in ${BUILD_SUMMARY_DIRS}; do
	if [ -d "${path}" ]; then
		catchup_number=${path##*/};
		catchup_display_number=$(printf "%.0f" "${catchup_number}");

		# Add to combined summary page
		# if summary/sessions/${catchup_number}/combined-summary.adoc exists,
		# then use it, else use the default template
		combined_summary_template="${summary_dir}/sessions/${catchup_number}/combined-summary.adoc";
		if [ ! -f combined_summary_template ]; then
			combined_summary_template="${summary_dir}/combined-summary-template.adoc";
		fi;
		sed \
			-e "s/{catchup_number}/${catchup_number}/g" \
			-e "s/{catchup_display_number}/${catchup_display_number}/g" \
			"${combined_summary_template}" \
		>> "${summary_dir}/autogenerated-combined-summary.adoc";

		asciidoctor \
			-a webfonts! \
			-a "catchup_number=${catchup_number}" \
			-a "catchup_display_number=${catchup_display_number}" \
			-o "${public_dir}/html/summary/${catchup_number}.html" \
			"${summary_dir}/individual-summary.adoc";

		# Lazy load images
		sed -i -e "s/<img/<img loading=\"lazy\"/g" "${public_dir}/html/summary/${catchup_number}.html";
	fi;
done;

# Build combined summary site
asciidoctor \
	-a webfonts! \
	-o "${public_dir}/html/summary/combined-summary.html" \
	"${summary_dir}/combined-summary.adoc";
# Lazy load images
sed -i -e 's/<img/<img loading="lazy"/g' "${public_dir}/html/summary/combined-summary.html";

echo "Summary pages build complete!";
echo;
