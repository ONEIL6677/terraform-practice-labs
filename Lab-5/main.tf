###############################################################################
# TERRAFORM FLASK APP DEPLOYMENT ON AWS
# ---------------------------------------------------------------------------
# This file provisions the complete AWS infrastructure needed to deploy a
# simple Flask web application on an EC2 instance. Here is what it builds:
#
#   1. A VPC          — a private network just for our resources
#   2. A Subnet       — a slice of that network in one availability zone
#   3. An Internet Gateway — connects our private network to the internet
#   4. A Route Table  — tells traffic where to go (to the internet gateway)
#   5. A Security Group — acts as a firewall (allows HTTP port 80 + SSH port 22)
#   6. An EC2 Instance — the virtual machine that will run our Flask app
#
# After the instance is ready, Terraform will:
#   - Copy our app.py file onto the server
#   - Install Python, pip, and Flask on the server
#   - Start the Flask app so it is accessible from a browser
###############################################################################


# ---------------------------------------------------------------------------
# PROVIDER
# ---------------------------------------------------------------------------
# Tell Terraform we are working with AWS and which region to deploy into.
# All resources below will be created in us-east-1 (North Virginia).
# ---------------------------------------------------------------------------


provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}


# ---------------------------------------------------------------------------
# VARIABLE — VPC CIDR BLOCK
# ---------------------------------------------------------------------------
# A variable lets us reuse a value in multiple places without repeating it.
# This CIDR block defines the IP address range for our entire VPC network.
# 10.0.0.0/16 means we can have IPs from 10.0.0.0 to 10.0.255.255
# ---------------------------------------------------------------------------


variable "cidr" {
  default     = "10.0.0.0/16"
  description = "The IP address range for the VPC network"
}


# ---------------------------------------------------------------------------
# SSH KEY PAIR
# ---------------------------------------------------------------------------
# An SSH key pair lets us securely connect to our EC2 instance from our
# local machine. We upload the PUBLIC key to AWS here. We keep the PRIVATE
# key on our local machine — AWS never sees the private key.
#
# Before running terraform apply, make sure you have generated an SSH key:
#   ssh-keygen -t rsa -b 4096
# This creates:
#   ~/.ssh/id_rsa       (private key — keep this secret, never share)
#   ~/.ssh/id_rsa.pub   (public key  — this is what we upload to AWS)
# ---------------------------------------------------------------------------


resource "aws_key_pair" "example" {
  key_name   = "terraform-demo-key"                # Name shown in AWS Console
  public_key = file("~/.ssh/id_rsa.pub")           # Path to your public key file
}


# ---------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# ---------------------------------------------------------------------------
# A VPC is like a private, isolated section of the AWS cloud — think of it
# as your own personal data center within AWS. All our resources will live
# inside this VPC and communicate privately with each other.
# ---------------------------------------------------------------------------


resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr # Uses the variable we defined above: 10.0.0.0/16

  tags = {
    Name = "terraform-flask-vpc"
  }
}


# ---------------------------------------------------------------------------
# SUBNET
# ---------------------------------------------------------------------------
# A subnet is a smaller network carved out of the VPC. Think of the VPC as
# a city and the subnet as one neighbourhood in that city.
#
# map_public_ip_on_launch = true means every EC2 instance launched in this
# subnet will automatically get a public IP address so it can be reached
# from the internet.
# ---------------------------------------------------------------------------


resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id   # Attach this subnet to our VPC
  cidr_block              = "10.0.0.0/24"      # IPs range: 10.0.0.0 to 10.0.0.255 (256 addresses)
  availability_zone       = "us-east-1a"       # Physical data center location in AWS region
  map_public_ip_on_launch = true               # Auto-assign public IP to instances in this subnet

  tags = {
    Name = "terraform-flask-subnet"
  }
}


# ---------------------------------------------------------------------------
# INTERNET GATEWAY
# ---------------------------------------------------------------------------
# An Internet Gateway is the door between our VPC and the public internet.
# Without this, nothing inside our VPC can talk to the outside world, and
# nothing outside can reach our resources. Think of it as the front gate
# of our private neighbourhood.
# ---------------------------------------------------------------------------


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id # Attach the gateway to our VPC

  tags = {
    Name = "terraform-flask-igw"
  }
}


# ---------------------------------------------------------------------------
# ROUTE TABLE
# ---------------------------------------------------------------------------
# A route table is like a GPS for network traffic — it tells traffic where
# to go based on the destination IP address.
#
# The rule below says: "For any traffic going anywhere (0.0.0.0/0),
# send it through the Internet Gateway." This is what makes our subnet
# publicly accessible.
# ---------------------------------------------------------------------------


resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id # Attach this route table to our VPC

  route {
    cidr_block = "0.0.0.0/0"                  # Match ALL outbound traffic
    gateway_id = aws_internet_gateway.igw.id  # Send it through the internet gateway
  }

  tags = {
    Name = "terraform-flask-route-table"
  }
}


# ---------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATION
# ---------------------------------------------------------------------------
# A route table only takes effect when it is associated with a subnet.
# Here we link our public route table to our subnet so the routing rules
# above apply to traffic coming from and going to our subnet.
# ---------------------------------------------------------------------------

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id      # The subnet we created above
  route_table_id = aws_route_table.RT.id   # The route table we created above
}


# ---------------------------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------------------------
# A security group is a virtual firewall that controls what traffic is
# allowed in (ingress) and out (egress) of our EC2 instance.
#
# We allow:
#   - Port 80  (HTTP)  — so users can visit our Flask app in a browser
#   - Port 22  (SSH)   — so we can connect to the server from our terminal
#   - All outbound traffic — so the server can download packages and updates
#
# WARNING: cidr_blocks = ["0.0.0.0/0"] on SSH means anyone on the internet
# can attempt to connect. For production, replace with your own IP address.
# ---------------------------------------------------------------------------


resource "aws_security_group" "webSg" {
  name   = "web-security-group"
  vpc_id = aws_vpc.myvpc.id

  # Allow incoming HTTP traffic on port 80 from anywhere
  # This is how users will access the Flask web application
  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 means allow from ANY IP address
  }
   _____________________________________________________________________________
  # Allow incoming SSH traffic on port 22 from anywhere
  # This is how we connect to the server from our terminal
  # TIP: Replace 0.0.0.0/0 with your own IP for better security in production
  #_____________________________________________________________________________
  ingress {
    description = "Allow SSH access for server management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production e.g. ["YOUR_IP/32"]
  }
  _______________________________________________________________________________________
  # Allow ALL outbound traffic from the instance to the internet
  # This is needed so the server can download packages (apt, pip, etc.)
  ________________________________________________________________________________________
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0    # 0 means all ports
    to_port     = 0    # 0 means all ports
    protocol    = "-1" # -1 means all protocols (TCP, UDP, ICMP, etc.)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}


# ---------------------------------------------------------------------------
# EC2 INSTANCE
# ---------------------------------------------------------------------------
# This is the virtual machine (server) that will run our Flask application.
#
# ami           = the operating system image (Ubuntu 22.04 in us-east-1)
# instance_type = the size of the server (t2.micro = 1 vCPU, 1GB RAM — Free Tier)
# key_name      = the SSH key we created above so we can log in
#
# After the instance starts, Terraform uses three steps:
#   1. connection  — establishes an SSH session to the running server
#   2. file        — copies our app.py from local machine to the server
#   3. remote-exec — runs commands on the server to install Flask and start the app
# ---------------------------------------------------------------------------


resource "aws_instance" "server" {
  ami                    = "ami-0261755bbcb8c4a84" # Ubuntu 22.04 LTS (us-east-1) — update if using a different region
  instance_type          = "t2.micro"              # Free Tier eligible — 1 vCPU, 1GB RAM
  key_name               = aws_key_pair.example.key_name         # SSH key pair for login
  vpc_security_group_ids = [aws_security_group.webSg.id]         # Attach our firewall rules
  subnet_id              = aws_subnet.sub1.id                    # Place the instance in our subnet


  # -------------------------------------------------------------------------
  # CONNECTION BLOCK
  # -------------------------------------------------------------------------
  # This tells Terraform HOW to connect to the EC2 instance after it boots.
  # Terraform needs this connection to run the file and remote-exec provisioners.
  #
  # type        = SSH (secure shell — the standard way to connect to Linux servers)
  # user        = "ubuntu" is the default admin user for Ubuntu AMIs on AWS
  # private_key = the private key on our LOCAL machine (matches the public key we uploaded)
  # host        = the public IP address of this EC2 instance (self = this resource)
  # -------------------------------------------------------------------------


  connection {
    type        = "ssh"
    user        = "ubuntu"                 # Default user for Ubuntu AMIs — change to "ec2-user" for Amazon Linux
    private_key = file("~/.ssh/id_rsa")   # Path to your local private key — must match the public key uploaded above
    host        = self.public_ip           # self.public_ip = the public IP of THIS EC2 instance
  }


  # -------------------------------------------------------------------------
  # FILE PROVISIONER
  # -------------------------------------------------------------------------
  # This copies our Flask application file (app.py) from our LOCAL machine
  # to the remote EC2 instance. Think of it like a secure file transfer (SCP).
  #
  # source      = path to the file on YOUR computer (where terraform apply runs)
  # destination = path where the file should be placed ON the remote server
  # -------------------------------------------------------------------------


  provisioner "file" {
    source      = "app.py"                   # app.py must exist in the same folder as main.tf
    destination = "/home/ubuntu/app.py"      # Where the file will live on the EC2 instance
  }



  # -------------------------------------------------------------------------
  # REMOTE-EXEC PROVISIONER
  # -------------------------------------------------------------------------
  # This runs a list of shell commands ON the remote EC2 instance over SSH.
  # These commands install the required software and start the Flask app.
  #
  # The commands run in order — if any command fails, Terraform will report
  # the error and stop. Each command is explained below.
  # -------------------------------------------------------------------------


  provisioner "remote-exec" {
    inline = [
      # Print a message to confirm the connection is working
      "echo 'Connected to EC2 instance successfully — starting setup...'",

      # Update the list of available packages so apt knows about the latest versions
      "sudo apt update -y",

      # Install Python 3 pip — the package manager for Python libraries
      "sudo apt-get install -y python3-pip",

      # Navigate into the home directory where app.py was copied
      "cd /home/ubuntu",

      # Install the Flask web framework using pip
      # --break-system-packages is required on Ubuntu 22.04+ to install pip packages globally
      "sudo pip3 install flask --break-system-packages",

      # Start the Flask app in the background using & so Terraform does not wait forever
      # nohup ensures the app keeps running even after the SSH session ends
      # Output (logs) are saved to app.log so we can debug if something goes wrong
      "nohup sudo python3 app.py > /home/ubuntu/app.log 2>&1 &",

      # Wait 3 seconds to give Flask time to start before Terraform checks and exits
      "sleep 3",

      # Confirm the app started successfully by printing a final message
      "echo 'Flask app started successfully — visit http://PUBLIC_IP to see it running'",
    ]
  }

  tags = {
    Name = "terraform-flask-server"
  }
}


# ---------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------
# Outputs are like a summary printed at the end of terraform apply.
# They display useful information about the resources we just created.
#
# After apply completes you will see the public IP in the terminal.
# Open a browser and visit: http://<public_ip> to see the Flask app.
# ---------------------------------------------------------------------------


output "public_ip" {
  description = "The public IP address of the Flask web server"
  value       = aws_instance.server.public_ip
}

output "app_url" {
  description = "The URL to access the Flask application in a browser"
  value       = "http://${aws_instance.server.public_ip}"
}
