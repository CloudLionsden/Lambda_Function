#!/bin/bash
rm -f lambda.zip
zip lambda.zip lambda_function.py
echo "Lambda package created: lambda.zip"

