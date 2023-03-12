1. Create a virtual machine instance that serves a static website that displays the following details of the instance

Instance id

IP address

mac address

Done

2.  Build a custom health check system that does the following:

checks the health of any given endpoint(s) based on its health check configuration

alerts the team about the health check status of the endpoint(s)

      Note: Do not use any third party health monitoring tools directly
Done 

3.  Automate the provisioning of both 1 & 2 systems in a highly available environment using terraform

Write the terraform code in such a manner that it can even be used by non-developers to replicate this setup in any account/ region of the chosen cloud . 