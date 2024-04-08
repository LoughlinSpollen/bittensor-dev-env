#! /usr/bin/env zsh
set -e -u

# check the OS is MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "installing dev env on MacOS"
else
    echo "command install-dev only supports MacOS"
    exit
fi   

echo "this script will install the following dependencies:"
echo "1. git"
echo "2. cmake"
echo "3. openssl"
echo "4. protobuf"
echo "5. python 3.9 or greater"
echo "6. llvm@14"
echo "7. rust"
echo "8. curl"
echo "9. hashcat"
echo "10. bittensor & subtensor"
echo "11. compute_subnet"
echo
echo -n "Do you want to continue? (y/n) " 
read REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit
fi

install_xcode()
{
    # check xcode is installed
    xcodebuild -version 2> /dev/null 2>&1
    if [ ! $? -eq 0 ] ; then
        xcode-select --install
    fi
}

install_brew()
{
    which -s brew
    if [ ! $? -eq 0 ] ; then
        echo "installing brew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

is_installed()
{
  command -v "$1" >/dev/null 2>&1
}

install() 
{
  if is_installed $1; then
    echo "$1 already installed"
  else
    echo "installing $"
    brew install $1
  fi
}

reload_shell()
{
    exec $SHELL -l
}

install_python()
{
    # check ptyhon version is 3.9 or greater
    ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
    if [ "$ver" -lt "39" ]; then
        echo "python 3.9 or greater required"
        # check if pyenv is installed
        if is_installed pyenv; then
            echo "pyenv already installed"
        else
            # ask user do they want to install pyenv
            echo -n "Do you want to install pyenv? (y/n) "
            read REPLY
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "installing pyenv"
                brew install pyenv
                echo "" >> ~/.zshrc
                echo "# Pyenv" >> ~/.zshrc
                echo 'export PYENV_ROOT="$HOME/.pyenv/shims"' >> ~/.zshrc
                echo 'export PATH="$PYENV_ROOT:$PATH"' >> ~/.zshrc
                echo 'export PIPENV_PYTHON="$PYENV_ROOT/python"' >> ~/.zshrc
                echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
                echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
                echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
                echo 'pyenv global 3.9.17' >> ~/.zshrc
                reload_shell
            else
                echo "please install python 3.9 or greater"
                exit
            fi 
        fi
    fi
}

install_llvm()
{
    # clang version dependency issue: 
    # https://github.com/rust-rocksdb/rust-rocksdb/issues/768#issuecomment-1995457749
    ver=$(llvm-config --version)
    if [[ "$ver" == "14.0.6" ]]; then    
        echo "llvm@14 already installed"
    else
        echo "2 installing llvm@14"
        if is_installed clang; then
            echo "llvm already installed"
            echo -n "Due to a compiler error, llvm@14 is required. Continue to install llvm@14? (y/n) "
            read REPLY
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit
            fi
        fi
        echo "installing llvm@14"
        brew install llvm@14
        echo "" >> ~/.zshrc
        echo "# LLVM" >> ~/.zshrc    
        echo 'export LDFLAGS="-L/usr/local/opt/llvm@14/lib"' >> ~/.zshrc
        echo 'export CPPFLAGS="-I/usr/local/opt/llvm@14/include"' >> ~/.zshrc
        echo 'export PATH="/usr/local/opt/llvm@14/bin:$PATH"' >> ~/.zshrc   
        reload_shell 
    fi
}

install_rust()
{
    if is_installed rustup; then
        echo "rust already installed"
    else
        echo "installing rust"
        curl https://sh.rustup.rs -sSf | sh

        echo "" >> ~/.zshrc
        echo "# Rust" >> ~/.zshrc
        echo '. $HOME/.cargo/env' >> ~/.zshrc
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
        reload_shell
    fi
}

install_protobuf()
{
    if is_installed protoc; then
        echo "protobuf already installed"
    else
        echo "installing protobuf"
        brew install protobuf
    fi
}


install_bittensor()
{
    CURRENT_DIR=$(pwd)
    cd ..

    if is_installed btcli; then
        echo "bittensor already installed"
        echo -n "Do you want to reinstall bittensor? (y/n) "
        read REPLY
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ ! -d "/tmp/bittensor/" ]; then
              rm -rf /tmp/bittensor/              
            fi
            if [ ! -d "~/.bittensor/wallets" ]; then
              rm -rf ~/.bittensor/wallets
            fi
            # check if Compute-Subnet python package is installed
            # it may have a dependency on an older version of bittensor
            pip list -v Compute-Subnet > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                pip uninstall -y Compute-Subnet
            fi
        else
            return 0
        fi
    fi

    echo "installing bittensor"    
    if [ -d "~/.bittensor/" ]; then
        rm -rf ~/.bittensor
    fi

    git clone https://github.com/opentensor/bittensor.git ~/.bittensor/bittensor/ 
    cd ~/.bittensor/bittensor/
    git fetch origin master
    git checkout master
    pip install bittensor -e ~/.bittensor/bittensor/
    cd $CURRENT_DIR
    

    echo "installing subtensor"
    cd ..
    if [ -d "./subtensor" ]; then
        rm -rf ./subtensor/              
    fi
    git clone https://github.com/opentensor/subtensor.git
    cd subtensor
    git fetch origin main
    git checkout main
    ./scripts/init.sh
    cargo build --release --features pow-faucet
    cd $CURRENT_DIR
}

install_compute_subnet()
{
    # assuming compute subnet is cloned
    echo "installing compute"
    pip install -r requirements.txt
    pip install --no-deps -r requirements-compute.txt
    pip install -e .
}


install_xcode
install_brew
install_python
install_llvm
install curl
install_rust
install git
install cmake
install openssl # libssl-dev, libudev-dev dependency
install hashcat
install_protobuf 
install_bittensor
install_compute_subnet



