#!/bin/bash
# Tool definitions registry for dx tools command
# This file is sourced by tools.sh - do not execute directly.

# Newline-separated list (IFS=$'\n\t' is set by the sourcing script)
MANAGED_TOOLS="git
dotnet
node
terraform
az
gh
docker
playwright
claude
psql
jq
yq
python
ansible
dotnet-ef
ripgrep
liquibase"

# Helper: map tool name to function prefix (hyphens to underscores)
_tool_func_prefix() {
  echo "$1" | tr '-' '_'
}

_ensure_sudo() {
  if [[ $EUID -ne 0 ]] && ! command -v sudo &>/dev/null; then
    print_error "sudo is required but not available. Run as root or install sudo."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Dispatcher helpers — tools.sh calls these, they resolve to per-tool funcs
# ---------------------------------------------------------------------------

tool_check() {
  local prefix
  prefix=$(_tool_func_prefix "$1")
  "tool_${prefix}_check"
}

tool_version() {
  local prefix
  prefix=$(_tool_func_prefix "$1")
  "tool_${prefix}_version"
}

tool_install() {
  local prefix
  prefix=$(_tool_func_prefix "$1")
  "tool_${prefix}_install"
}

tool_update() {
  local prefix
  prefix=$(_tool_func_prefix "$1")
  "tool_${prefix}_update"
}

# ===========================================================================
# Tool definitions — for each tool: _check, _version, _install, _update
# ===========================================================================

# --- git ---
tool_git_check()   { command -v git &>/dev/null; }
tool_git_version() { git --version 2>/dev/null | awk '{print $3}'; }
tool_git_install() { _ensure_sudo && sudo apt-get update && sudo apt-get install -y git; }
tool_git_update()  { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y git; }

# --- dotnet ---
tool_dotnet_check()   { command -v dotnet &>/dev/null; }
tool_dotnet_version() { dotnet --version 2>/dev/null; }
tool_dotnet_install() {
  print_info "Installing .NET SDK (channel 9.0)..."
  local install_script
  install_script=$(mktemp)
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$install_script"
  chmod +x "$install_script"
  "$install_script" --channel 9.0
  rm -f "$install_script"
  if ! echo "$PATH" | tr ':' '\n' | grep -q "$HOME/.dotnet"; then
    export PATH="$PATH:$HOME/.dotnet"
    print_warning "Add to your shell profile: export PATH=\$PATH:\$HOME/.dotnet"
  fi
}
tool_dotnet_update() { tool_dotnet_install; }

# --- node ---
tool_node_check()   { command -v node &>/dev/null; }
tool_node_version() { node --version 2>/dev/null; }
tool_node_install() {
  print_info "Installing Node.js..."
  _ensure_sudo
  
  # Try NodeSource (latest LTS) first
  if curl -fsSL --connect-timeout 5 https://deb.nodesource.com/setup_lts.x 2>/dev/null | sudo -E bash - 2>/dev/null; then
    print_info "Using NodeSource repository..."
    sudo apt-get install -y nodejs
  else
    # Fallback to Ubuntu repos if NodeSource fails (e.g., firewall/Zscaler blocking)
    print_warning "NodeSource unavailable, using Ubuntu repos..."
    sudo apt-get update && sudo apt-get install -y nodejs npm
  fi
}
tool_node_update() { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y nodejs npm; }

# --- terraform ---
tool_terraform_check()   { command -v terraform &>/dev/null; }
tool_terraform_version() { terraform --version 2>/dev/null | head -1; }
tool_terraform_install() {
  print_info "Installing Terraform..."
  _ensure_sudo
  sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt-get install -y terraform
}
tool_terraform_update() { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y terraform; }

# --- az (Azure CLI) ---
tool_az_check()   { command -v az &>/dev/null; }
tool_az_version() { az version 2>/dev/null | grep '"azure-cli"' | awk -F'"' '{print $4}'; }
tool_az_install() {
  print_info "Installing Azure CLI..."
  _ensure_sudo
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}
tool_az_update() { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli; }

# --- gh (GitHub CLI) ---
tool_gh_check()   { command -v gh &>/dev/null; }
tool_gh_version() { gh --version 2>/dev/null | head -1; }
tool_gh_install() {
  print_info "Installing GitHub CLI..."
  _ensure_sudo
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
  sudo apt-get update && sudo apt-get install -y gh
}
tool_gh_update() { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y gh; }

# --- docker ---
tool_docker_check()   { command -v docker &>/dev/null; }
tool_docker_version() { docker --version 2>/dev/null; }
tool_docker_install() {
  print_info "Installing Docker..."
  _ensure_sudo
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}
tool_docker_update() { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; }

# --- playwright ---
tool_playwright_check()   { command -v npx &>/dev/null && npm list -g playwright &>/dev/null; }
tool_playwright_version() { npx playwright --version 2>/dev/null; }
tool_playwright_install() {
  print_info "Installing Playwright..."
  if ! command -v npm &>/dev/null; then
    print_error "npm is required. Install node first: dx tools install node"
    return 1
  fi
  sudo npm install -g playwright
  npx playwright install --with-deps
}
tool_playwright_update() {
  if ! command -v npm &>/dev/null; then
    print_error "npm is required. Install node first: dx tools install node"
    return 1
  fi
  sudo npm update -g playwright
  npx playwright install --with-deps
}

# --- claude ---
tool_claude_check()   { command -v claude &>/dev/null; }
tool_claude_version() { claude --version 2>/dev/null; }
tool_claude_install() {
  print_info "Installing Claude Code..."
  if ! command -v npm &>/dev/null; then
    print_error "npm is required. Install node first: dx tools install node"
    return 1
  fi
  sudo npm install -g @anthropic-ai/claude-code
}
tool_claude_update() {
  if ! command -v npm &>/dev/null; then
    print_error "npm is required. Install node first: dx tools install node"
    return 1
  fi
  sudo npm update -g @anthropic-ai/claude-code
}

# --- psql (PostgreSQL client) ---
tool_psql_check()   { command -v psql &>/dev/null; }
tool_psql_version() { psql --version 2>/dev/null; }
tool_psql_install() { _ensure_sudo && sudo apt-get update && sudo apt-get install -y postgresql-client; }
tool_psql_update()  { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y postgresql-client; }

# --- jq ---
tool_jq_check()   { command -v jq &>/dev/null; }
tool_jq_version() { jq --version 2>/dev/null; }
tool_jq_install() { _ensure_sudo && sudo apt-get update && sudo apt-get install -y jq; }
tool_jq_update()  { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y jq; }

# --- yq ---
tool_yq_check()   { command -v yq &>/dev/null; }
tool_yq_version() { yq eval --version 2>/dev/null || yq --version 2>/dev/null | head -1; }
tool_yq_install() {
  _ensure_sudo
  if command -v snap &>/dev/null; then
    sudo snap install yq
  else
    sudo apt-get update && sudo apt-get install -y yq
  fi
}
tool_yq_update() {
  if command -v snap &>/dev/null && snap list yq &>/dev/null; then
    sudo snap refresh yq
  else
    _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y yq
  fi
}

# --- python ---
tool_python_check()   { command -v python3 &>/dev/null; }
tool_python_version() { python3 --version 2>/dev/null; }
tool_python_install() { _ensure_sudo && sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv; }
tool_python_update()  { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y python3 python3-pip python3-venv; }

# --- ansible ---
tool_ansible_check()   { command -v ansible &>/dev/null; }
tool_ansible_version() { ansible --version 2>/dev/null | head -1; }
tool_ansible_install() {
  print_info "Installing Ansible..."
  _ensure_sudo
  # Use apt (respects PEP 668 on Ubuntu 24.04+); installs both ansible and ansible-core
  sudo apt-get update && sudo apt-get install -y ansible
}
tool_ansible_update() {
  _ensure_sudo
  sudo apt-get update && sudo apt-get install --only-upgrade -y ansible
}

# --- dotnet-ef ---
tool_dotnet_ef_check() {
  if command -v dotnet-ef &>/dev/null; then
    return 0
  fi
  dotnet tool list -g 2>/dev/null | grep -q dotnet-ef
}
tool_dotnet_ef_version() { dotnet ef --version 2>/dev/null || dotnet-ef --version 2>/dev/null; }
tool_dotnet_ef_install() {
  print_info "Installing dotnet-ef..."
  if ! command -v dotnet &>/dev/null; then
    print_error "dotnet is required. Install it first: dx tools install dotnet"
    return 1
  fi
  dotnet tool install --global dotnet-ef
}
tool_dotnet_ef_update() {
  if ! command -v dotnet &>/dev/null; then
    print_error "dotnet is required. Install it first: dx tools install dotnet"
    return 1
  fi
  dotnet tool update --global dotnet-ef
}

# --- ripgrep ---
tool_ripgrep_check()   { command -v rg &>/dev/null; }
tool_ripgrep_version() { rg --version 2>/dev/null | head -1; }
tool_ripgrep_install() { _ensure_sudo && sudo apt-get update && sudo apt-get install -y ripgrep; }
tool_ripgrep_update()  { _ensure_sudo && sudo apt-get update && sudo apt-get install --only-upgrade -y ripgrep; }

# --- liquibase ---
tool_liquibase_check()   { command -v liquibase &>/dev/null; }
tool_liquibase_version() { liquibase --version 2>&1 | grep -i "Liquibase Version:" | awk '{print $NF}'; }
tool_liquibase_install() {
  print_info "Installing Liquibase Community CLI..."
  _ensure_sudo
  
  if ! command -v java &>/dev/null; then
    print_error "Java is required. Installing default JRE..."
    sudo apt-get update && sudo apt-get install -y default-jre
  fi
  
  local install_dir="/opt/liquibase"
  local temp_dir
  temp_dir=$(mktemp -d)
  
  print_info "Downloading Liquibase v5.0.2..."
  if ! curl --connect-timeout 5 -fsSL "https://github.com/liquibase/liquibase/releases/download/v5.0.2/liquibase-5.0.2.tar.gz" -o "$temp_dir/liquibase.tar.gz"; then
    print_warning "Could not fetch from GitHub, trying apt..."
    if apt-cache search liquibase 2>/dev/null | grep -q '^liquibase'; then
      sudo apt-get update && sudo apt-get install -y liquibase
      rm -rf "$temp_dir"
      return 0
    fi
    print_error "Could not find or download Liquibase"
    rm -rf "$temp_dir"
    return 1
  fi
  
  sudo rm -rf "$install_dir"
  sudo mkdir -p "$install_dir"
  sudo tar -xzf "$temp_dir/liquibase.tar.gz" -C "$install_dir"
  
  # Create wrapper script
  sudo tee /usr/local/bin/liquibase > /dev/null << 'LQSCRIPT'
#!/bin/bash
LIQUIBASE_HOME="/opt/liquibase"
LIQUIBASE_JAR="$LIQUIBASE_HOME/lib/liquibase-core.jar"
if [[ ! -f "$LIQUIBASE_JAR" ]]; then
  echo "Error: Liquibase JAR not found at $LIQUIBASE_JAR"
  exit 1
fi
CLASSPATH="$LIQUIBASE_JAR"
for jar in "$LIQUIBASE_HOME"/lib/*.jar; do
  CLASSPATH="$CLASSPATH:$jar"
done
exec java -cp "$CLASSPATH" liquibase.integration.commandline.LiquibaseCommandLine "$@"
LQSCRIPT
  
  sudo chmod +x /usr/local/bin/liquibase
  rm -rf "$temp_dir"
  print_success "Liquibase installed to $install_dir"
}
tool_liquibase_update() {
  print_info "Updating Liquibase Community CLI..."
  tool_liquibase_install
}
