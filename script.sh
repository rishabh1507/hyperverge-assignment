#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo service httpd start
sudo chkconfig httpd on
echo "<html><h1>Terraform assignment !</h1><html>" | sudo tee /var/www/html/index.html
echo "Hostname: `hostname -f` | 'Instance Id': `wget -q -O - http://169.254.169.254/latest/meta-data/instance-id` | 'MAC Address': `cat /sys/class/net/*/address` " >> /var/www/html/index.html

touch /tmp/send_email.py
chmod 777 /tmp/send_email.py
echo '
import smtplib
import ssl
from email.message import EmailMessage

# Define email sender and receiver
email_sender = "riserishabh15@gmail.com"
email_password = "ypwrvlqtvpxehuuv"
email_receiver = "srivastava829@gmail.com"

# Set the subject and body of the email
subject = "Connection failure"
body = """
  Hi,
    Health check have failed please check.
    
    Thanks,
    Healthchecker
"""

em = EmailMessage()
em["From"] = email_sender
em["To"] = email_receiver
em["Subject"] = subject
em.set_content(body)

# Add SSL (layer of security)
context = ssl.create_default_context()

# Log in and send the email
with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as smtp:
    smtp.login(email_sender, email_password)
    smtp.sendmail(email_sender, email_receiver, em.as_string())
' > /tmp/send_email.py

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

