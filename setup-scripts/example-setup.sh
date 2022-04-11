#!/bin/bash
. /home/ubuntu/.env # Load environment variables

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then echo "true"
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi