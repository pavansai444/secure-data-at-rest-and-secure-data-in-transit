# Use the official Ubuntu base image
FROM ubuntu:latest

# Update package list and install cryptsetup, curl, and jq in noninteractive mode
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cryptsetup curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Set default command
CMD ["bash"]

