
# Code for looking up the latest Amazon Linux 2 AMI
# in the current region.
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# The instances represent the web app servers
resource "aws_instance" "webapp_instances" {
  ami           = data.aws_ami.amazon-linux-2.id # Ubuntu 20.04 LTS // us-east-1
  instance_type = "t2.micro"
  count         = var.num-replicas
  subnet_id     = element(aws_subnet.app-subnets.*.id, count.index)

  # Optional - associate public IP address so instance can be reached from internet
  # For private subnets, this should be set to false (which is the default)

  associate_public_ip_address = var.associate_public_ip

  # this associates the instance with the security group
  vpc_security_group_ids = [aws_security_group.instances.id]

  # this code executes when the instance is created
  # here we are create a placeholder index.html file
  # that shows basic diagnostic information about the instance
  # http://169.254.169.254 is a special IP address that AWS
  # recognizes and provides metadata about the instance
  user_data = <<-EOF
          #!/bin/bash
          cat <<END_OF_FILE > index.html
          <html>
          <head>
            <title>AWS Diagnostic Details</title>
          </head>
          <body>
            <h1>Diagnostics for ${var.app-name}</h1>
            <h2>Hello World ${count.index}</h2>
            <h3>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h3>
            <p>Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
            <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
          </body>
          </html>
          END_OF_FILE
          python3 -m http.server 8080 &
          EOF

  # alternatively, setup nginx as the server
  # this will require outbound traffic to the internet
  # to download nginx.  This also requires apt-get on the image

  # user_data = <<-EOF
  #         #!/bin/bash
  #         apt-get update
  #         apt-get install -y nginx
  #         sed -i 's/listen 80;/listen 8080;/g' /etc/nginx/sites-enabled/default
  #         cat <<END_OF_FILE > /var/www/html/index.html
  #         <html>
  #         <head>
  #           <title>AWS Diagnostic Details</title>
  #         </head>
  #         <body>
  #           <h1>AWS Diagnostic Details</h1>
  #           <h2>Hello World ${count.index}</h2>
  #           <h3>Instance ID: \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h3>
  #           <p>Region: \$(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
  #           <p>Availability Zone: \$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
  #         </body>
  #         </html>
  #         END_OF_FILE
  #         systemctl enable nginx
  #         systemctl start nginx
  #         EOF


  # a simpler page
  # user_data       = <<-EOF
  #             #!/bin/bash
  #             echo "Hello, World ${count.index+1}" > index.html
  #             python3 -m http.server 8080 &
  #             EOF

}