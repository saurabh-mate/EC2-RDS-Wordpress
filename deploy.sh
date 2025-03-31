#!/bin/bash
set -e  # Exit immediately if any command fails
set -x  # Debugging mode (prints each command before execution)

terraform init
terraform apply -auto-approve
INSTANCE_IP=$(terraform output -raw instance_public_ip)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint | cut -d ':' -f1)

# Wait for SSH access
while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /home/saurabh/Downloads/tf-key.pem ubuntu@$INSTANCE_IP exit; do   
  echo "Waiting for SSH..."
  sleep 5
done

# Create .env file
cat <<EOT > /home/saurabh/Tasks/Automations/EC2-RDS-Wordpress/.env
WORDPRESS_DB_HOST=$RDS_ENDPOINT
WORDPRESS_DB_USER=saurabh
WORDPRESS_DB_PASSWORD=saurabh123
WORDPRESS_DB_NAME=wordpress
WORDPRESS_SITE_TITLE="My WordPress Site"
WORDPRESS_ADMIN_USER="admin"
WORDPRESS_ADMIN_PASSWORD="Admin@123"
WORDPRESS_ADMIN_EMAIL="admin@example.com"
EOT

# Copy .env file to instance
scp -i /home/saurabh/Downloads/tf-key.pem /home/saurabh/Tasks/Automations/EC2-RDS-Wordpress/.env ubuntu@$INSTANCE_IP:/home/ubuntu/.env

# Run Ansible Playbook
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

ssh -o StrictHostKeyChecking=no -i /home/saurabh/Downloads/tf-key.pem ubuntu@$INSTANCE_IP <<EOF
  set -e
  set -x

  # Wait for database to be ready
  while ! nc -z \$(grep WORDPRESS_DB_HOST /home/ubuntu/.env | cut -d '=' -f2) 3306; do
    echo "Waiting for MySQL to be ready..."
    sleep 10
  done

  # Start WordPress container
  docker run -d -p 80:80 \
    --env-file /home/ubuntu/.env \
    -v /home/ubuntu/wordpress:/var/www/html \
    --name wordpress-container \
    wordpress:latest

  # Wait for WordPress container to initialize
  sleep 10

  echo "Installing WP-CLI inside the container..."
  docker exec wordpress-container bash -c "
    apt update && apt install -y wget less &&
    wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&
    chmod +x /usr/local/bin/wp &&
    ln -s /usr/local/bin/wp /usr/bin/wp"
  
  echo "Checking if WordPress is already installed..."
  
  if docker exec wordpress-container bash -c "wp core is-installed --path='/var/www/html' --allow-root"; then
    echo "✅ WordPress is already installed!"
  else
    echo "Running WordPress installation..."
    docker exec wordpress-container bash -c "
      wp core install \
      --url='http://wordpress.purvesh.cloud' \
      --title='My WordPress Site' \
      --admin_user='saurabh' \
      --admin_password='saurabh123' \
      --admin_email='example@gmail.com' \
      --path='/var/www/html' \
      --allow-root"
    
    echo "✅ WordPress setup complete!"
  fi
EOF

echo "✅ WordPress successfully deployed!"
echo "🌐 Website URL: http://$INSTANCE_IP"
echo "🔗 Admin Login: http://$INSTANCE_IP/wp-admin"
echo "🌍 Custom Domain: http://wordpress.purvesh.cloud"
