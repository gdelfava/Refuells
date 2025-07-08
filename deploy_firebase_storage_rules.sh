#!/bin/bash

echo "Deploying Firebase Storage rules..."
firebase deploy --only storage

echo "Storage rules deployed successfully!" 