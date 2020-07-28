#!/usr/bin/env bash
function PrintUsage(){
  echo "RUVM -- RUst Version Manager"
  echo "Usage : "
  echo "install [version] : Install rust Version"
  echo "use [installed-version] : Use rust version"
  echo "update : Update ruvm"
  echo "Examples : "
  echo "Install :"
  echo "  ruvm install 1.45.0"
  echo "  ruvm install 1.44.0"
  echo "  ruvm install 1.5.0"
  echo "Use :"
  echo "  ruvm use 1.45.0"
  echo "  ruvm use 1.44.0"
  echo "  ruvm use 1.5.0"
}
function FindTool() {
  # Use Xcrun to find tool
  xcrun --find $1
}
function CheckForTools(){
  # Curl
  CURL=$(FindTool "curl")
  # Grep
  GREP=$(FindTool "grep")
  # Bash
  BASH=$(FindTool "bash")
  # Cmake
  CMAKE=$(FindTool "cmake")
  if [ ! -f $CURL ]; then
    Log "Curl was not found on your System!"
    Log "If you have Brew run : "
    Log "brew install curl"
    exit
  fi
  if [ ! -f $GREP ]; then
    Log "Grep was not found on your System!"
    Log "If you have Brew run : "
    Log "brew install grep"
    exit
  fi
  if [ ! -f $BASH ]; then
    Log "Bash was not found on your System!"
    Log "If you have Brew run : "
    Log "brew install bash"
    exit
  fi
  if [ ! -f $CMAKE ]; then
    Log "Cmake was not found on your System!"
    Log "If you have Brew run : "
    Log "brew install cmake"
    exit
  fi
}
function Error(){
  echo "Error! : $1"
  exit 1
}
function Info(){
  echo "INFO : $1"
}
function Log() {
  # Output these little bars based off the ones used in the homebrew installer
  echo "===> $1"
}
function Warning(){
  echo "Warning! : $1"
}
function Download() {
  echo "Downloading..."
  curl $1
}
function SetOSData() {
  ARCH=$(uname -m)
  OS=$(uname -s)
  if [[ $OS == "Darwin" ]]; then
    OSTYPE="apple-darwin"
  else
    OSTYPE=$OS
  fi
}
function GenerateUrl(){
  # Generate a url to download rust from
  ARCH=$(uname -m)
  OS=$(uname -s)
  if [[ $OS == "Darwin" ]]; then
    OSTYPE="apple-darwin"
  else
    OSTYPE=$OS
  fi
  echo "https://static.rust-lang.org/dist/rust-$1-$ARCH-$OSTYPE.tar.gz"
}
# Make sure user has tools in there path
CheckForTools
if [[ ! $1 ]]; then
  PrintUsage
fi
if [[ $1 == "update" ]]; then
  echo "INFO : Pulling..."
  git pull
fi
if [[ $1 == "install" ]]; then
  version=$2
  echo "Rust Install Version : $version" >> log
  PACKAGE_URL=$(GenerateUrl $version)
  echo "Package url : $PACKAGE_URL" >> log
  PACKAGE_DIR="$RUVM/packages"
  echo "Package Dir : $PACKAGE_DIR" >> log
  INSTALL_PREFIX="$RUVM/packages/rust-$version"
  echo "Install Prefix : $INSTALL_PREFIX" >> log
  if [ -d "$INSTALL_PREFIX" ]; then
    echo "rust-$1 is already installed!" >> log
    Error "rust-$1 is already installed!"
  fi
  if [ ! -d "$PACKAGE_DIR" ]; then
    echo "$PACKAGE_DIR Does not exist!" >> log
    Error "$PACKAGE_DIR Does not exist!"
  fi
  # Test if we can download rust from url
  Log "Installing rust-$version..."
  curl -L# $PACKAGE_URL --output rust-$version.tar.gz
  Log "Untarring..."
  echo "Tar : " >> log
  tar -xvf rust-$version.tar.gz &>log
  echo "Done!" >> log
  Log "Installing..."
  echo "Running SetOSData..." >> log
  SetOSData
  cd rust-$version-$ARCH-$OSTYPE
  echo "CWD : rust-$version-$ARCH-$OSTYPE" >> log
  echo "sh install.sh --prefix=$RUVM/packages/rust-$version" >> log
  sh install.sh --prefix=$RUVM/packages/rust-$version &>log
  if [[ $? == 1 ]]; then
    Error "Could not install rust-$version please check the file named 'log'"
  fi
  Log "Finishing Up..."
  BIN_FILE_COUNT=$(ls -1 $RUVM/bin | wc -l)
  if [[ $BIN_FILE_COUNT == 1 ]]; then
    echo "Running 'ln -s $RUVM/packages/rust-$version/bin/* $RUVM/bin/'" >> log
    ln -s $RUVM/packages/rust-$version/bin/* $RUVM/bin/
  else
    Warning "Another version of rust is installed! To use this version run"
    Log "ruvm use $version"
  fi
  Log "Cleaning Up..."
  cd $RUVM
  rm rust-$version.tar.gz
  rm -rf rust-$version-$ARCH-$OSTYPE
  Log "Rust-$version Installed!"
fi
if [[ $1 == "use" ]]; then
  version=$2
  if [[ ! -d "$RUVM/packages/rust-$version" ]]; then
    Log "You do not have rust $version installed!"
    Log "You can install it like this"
    echo "ruvm install $version"
    exit 1
  fi
  Log "Unlinking old Binaries before linking..."
  cd $RUVM/bin
  echo "Unlinking with 'find . -type l'" >> ../log
  rm $(find . -type l) &>../log
  Log "Linking Package Binaries..."
  echo "Running 'ln -s $RUVM/packages/rust-$version/bin/* $RUVM/bin/' : " >> ../log
  ln -s $RUVM/packages/rust-$version/bin/* $RUVM/bin/
  Log "Now using rust-$version"
fi
