header "Found private ssh key config variable, creating id_rsa"
mkdir -p ~/.ssh/
chmod 700 ~/.ssh/

echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa

echo "StrictHostKeyChecking=no" > ~/.ssh/config
chmod 600 ~/.ssh/config

mkdir -p "$1/.profile.d"
cat > "$1/.profile.d/00-clobber-ssh-key.sh" << EOF
echo "Unsetting ssh deploy key" 2>&1
unset -v SSH_KEY
EOF
