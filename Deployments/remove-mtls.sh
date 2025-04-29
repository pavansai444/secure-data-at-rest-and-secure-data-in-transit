#!/bin/bash

echo "Deleting PeerAuthentication resources..."
kubectl delete peerauthentication --all -n default

echo "Deleting DestinationRule resources..."
kubectl delete destinationrule --all -n default

echo "Deleting AuthorizationPolicy resources..."
kubectl delete authorizationpolicy --all -n default

echo "All specified resources have been deleted."
echo "Press Enter to continue..."
read
