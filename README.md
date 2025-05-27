# 2tierarchitecture

This Project is to create WordPress Website. It will have a Wordpress application hosted on an EC2 Instance deployed in public subnet and uses RDS at the Database Layer in private subnet.

# Architecture Components

## Application Tier

Amazon EC2 – Hosts the Wordpress Application

Security Group – Controls inbound/outbound traffic to the EC2 instance.

## Database Tier

Amazon RDS - Manages the backend relational database (MySQL). It holds the User data, Posts ...etc from Wordpress Application

DB Subnet Group - Ensures the RDS instance is deployed into private subnets.

Security Group - Controls access to RDS (usually allows only the EC2 app server).

#Architecture Diagram

<img src="2tierarchitecture.png" alt="Architecture Diagram" width="500"/>
