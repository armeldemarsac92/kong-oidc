# Start from the absolute minimal base image
FROM scratch

# Copy your OIDC plugin's files directly into the image.
# This assumes the Dockerfile is at the root of your 'kong-oidc' repository
# and the plugin's main directory structure is 'kong/plugins/oidc/'.
# The destination '/' means it will be copied to the root of the scratch image,
# maintaining its relative path (e.g., /kong/plugins/oidc/).
COPY ./kong/plugins/oidc/ /

# The ENTRYPOINT is not strictly necessary for KongPluginInstallation images,
# as the operator extracts the tarball.
# ENTRYPOINT ["/bin/true"]
