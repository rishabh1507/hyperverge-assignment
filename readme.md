1. Create a virtual machine instance that serves a static website that displays the following details of the instance

Instance id
IP address
mac address
— Using the below code I was able to get the required details.
To implement the solution I created a bash script that installs and runs the apache server on the machine and then displays the below details using Linux commands.

The code for this is present in the script.sh


"Hostname: `hostname -f` 

'Instance Id': `wget -q -O - http://169.254.169.254/latest/meta-data/instance-id` 

'MAC Address': `cat /sys/class/net/*/address`





2.  Build a custom health check system that does the following:

checks the health of any given endpoint(s) based on its health check configuration
alerts the team about the health check status of the endpoint(s)

— I created a bash script that uses curl to get the status of the page. If the status is 200 then it will log Everything is working fine else it will run a python script which will send an email to the team. The python script uses smtplib + gmail creds to send email. Health checker uses cron and runs every minute for 24 hours to check the status of the endpoint



 Below is the code for health checker. You can also check the script.sh file



touch /tmp/healthcheck.sh
chmod 777 /tmp/healthcheck.sh
echo '
#!/bin/bash
result=$(curl -i `curl http://169.254.169.254/latest/meta-data/public-hostname` | head -n 1 | cut -d$" " -f2)
if [ $result -eq "200" ]
then
   echo "Everything is working fine - Healthchecker"
else
    /usr/bin/python3 /tmp/send_email.py
fi
' > /tmp/healthcheck.sh

sudo systemctl start crond
sudo systemctl enable crond
echo '* * * * * /tmp/healthcheck.sh' | crontab





3.  Automate the provisioning of both 1 & 2 systems in a highly available environment using terraform

Write the terraform code in such a manner that it can even be used by non-developers to replicate this setup in any account/ region of the chosen cloud . 


— I have automated the setup using terraform and have used the concept of horizontal scaling and  Application load balancer for highly available environments.

I have created 2 instances that have the static website running.
The instance are in two different region. Now ALB will distribute the incoming traffic across multiple instances of an application, ensuring that if any instance fails, traffic is automatically redirected to a healthy instance. This helps to ensure that the application remains available to users at all times, even if there are issues with individual instances.



The code for the automation is present in the main.tf file. 

The link which I have mentioned above is the ALB’s DNS



Below is the flow for alb ->
ALB -> listener -> target group -> ec2 instances



I have tried to write main.tf file in such a way that it can be used by a non-dev person.

By changing three parameters they can run the script in any AZ. The whole setup has been done using the three files
main.tf -> Has terraform automation code
script.sh -> Has the code for apache server and linux command to copy copy file and run crontab.
send_mail.py -> Code for sending alert
 