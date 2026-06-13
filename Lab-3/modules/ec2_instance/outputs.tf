# here we wewrite the expected output we need from terraform after we apply

# example print public ip of the ec2 instance we created

output "public-ip-address" {                 #write outputfollowed by resourcr name in quot
  value = aws_instance.example.public_ip     #print public_ip as output of the execution of terraforn
}