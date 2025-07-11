#set dotenv-required
#set dotenv-load
set shell := ["bash", "-uc"]
set windows-shell := ["bash", "-uc"]


ref_name := "git rev-parse --abbrev-ref HEAD"
major_branch_name := "git rev-parse --abbrev-ref HEAD | cut -d . -f 1"


_default:
    @just --list --unsorted --justfile {{justfile()}}

# Build the project
[group("project")]
build: clean _post-process-linkml-schema generate-documentation
    @echo
    @echo "All project artifacts have been generated and post-processed, and can found in: artifacts/"
    @echo

# Clean up the output directory
[group("project")]
clean:
    @echo "Cleaning up generated artifacts…"
    @echo
    @if [ -d "artifacts" ]; then \
        rm -rf "artifacts"; \
    fi
    mkdir -p "artifacts"
    @echo "… OK."
    @echo

# Post-process LinkML schema for preview or releasing
_post-process-linkml-schema:
    @echo "Copying source files to artifacts directory…"
    mkdir -p "artifacts"
    cp "model.linkml.yml" "artifacts/"
    @echo
    @echo "Setting version in LinkML schema…"
    @echo
    sed -i '/^version: .*$/d' "artifacts/model.linkml.yml"
    @if [ -z ${VERSION:-} ]; then \
        sed -i "/^name: .*$/a version: {{shell(ref_name)}}" "artifacts/model.linkml.yml"; \
    else \
        sed -i "/^name: .*$/a version: ${VERSION}" "artifacts/model.linkml.yml"; \
    fi
    @echo "… OK."
    @echo

# Generate documentation
[group("generators")]
generate-documentation: _post-process-linkml-schema
    @echo "Generating documentation…"
    @echo
    cp -r "documentation" "artifacts"
    mkdir -p "artifacts/documentation/modules/ontology/attachments"
    mkdir -p "artifacts/documentation/modules/ontology/examples"
    mkdir -p "artifacts/documentation/modules/ontology/images"
    mkdir -p "artifacts/documentation/modules/ontology/pages"
    mkdir -p "artifacts/documentation/modules/ontology/partials"
    touch "artifacts/documentation/modules/ontology/attachments/.gitkeep"
    touch "artifacts/documentation/modules/ontology/examples/.gitkeep"
    touch "artifacts/documentation/modules/ontology/images/.gitkeep"
    touch "artifacts/documentation/modules/ontology/pages/.gitkeep"
    touch "artifacts/documentation/modules/ontology/partials/.gitkeep"
    uv run linkml generate doc \
        --template-directory templates \
        -d "artifacts/documentation/modules/ontology/pages" \
        artifacts/model.linkml.yml
    @echo
    @echo Removing unwanted files…
    find "artifacts/documentation/modules/ontology/pages" -type f -name "*.md" ! -name "index.md" -delete
    @echo 'Renaming `.md` files to `.adoc` (required hack)…'
    for f in artifacts/documentation/modules/ontology/pages/*.md ; do \
        mv "$f" "${f/%.md/.adoc}"; \
    done
    echo "" > artifacts/documentation/modules/ontology/nav.adoc
    echo "- modules/ontology/nav.adoc" >> artifacts/documentation/antora.yml
    cp "model.drawio.svg" "artifacts/documentation/modules/ontology/images/"
    cp "artifacts/model.linkml.yml" "artifacts/documentation/modules/ontology/attachments/"
    @echo "… OK."
    @echo
    @echo -e "Generated documentation files at: artifacts/documentation"
    @echo

# Generate LinkML schema from Draw.io project
# [group("generators")]
# generate-linkml-schema:
#     TODO?
