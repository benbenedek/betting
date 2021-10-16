#!/bin/bash

# Start the rails process 
rails server -b 0.0.0.0 &
  
# Start the async job processor
rake jobs:work &
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?
