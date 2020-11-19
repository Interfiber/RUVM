#!/usr/bin/env bash
# Setup Varibles
# Make sure we are in the RUVM Directory!
cd $RUVM
function PrintUsage(){
  echo "RUVM -- RUst Version Manager"
  echo "Usage : "
  echo "install [version] : Install rust Version"
  echo "use [installed-version] : Use rust version"
  echo "update : Update ruvm"
  echo "use-shell [installed-version] : only use a version in the current shell. Not globally"
  echo "list : List installefd rust versions"
  echo "delink : Delinks the current version of rust being used"
  echo "remove [version] : Remove version of rust"
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
  # gpg
  if [ ! -f $CURL ]; then
    Log "Curl was not found on your System!"
    Log "If you have Brew run : "
    Log "brew install  curl"
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
function GetCurrent(){
  cat $RUVM/current
}
function Delink(){
    current=$(GetCurrent)
    Log "Delinking rust-$current..."
    rm $(find $RUVM/bin -type l)
    echo "Delinked rust-$current"
}
# Make sure user has tools in there path
CheckForTools
if [[ ! $1 ]]; then
  PrintUsage
fi
if [[ $1 == "update" ]]; then
  cd $RUVM
  echo "INFO : Pulling..."
  git pull
fi
if [[ $1 == "install" ]]; then
  SetOSData
  version=$2
  if [[ $version == "--lts" ]]; then
    # Set Version to the latest if user wants latest!
    version="1.48.0"
  fi
  echo "Rust Install Version : $version" >> log
  PACKAGE_URL=$(GenerateUrl $version)
  URL_CHECK=$(curl -Is $PACKAGE_URL | head -n1)
  if [[ "$URL_CHECK" =~ "404" ]]; then
    Error "The package rust-$version does not exist!"
  fi
  echo "Package url : $PACKAGE_URL" >> log
  SHA_URL="$PACKAGE_URL.sha256"
  echo "Sha256 : $SHA_URL" >> log
  PACKAGE_DIR="$RUVM/packages"
  echo "Package Dir : $PACKAGE_DIR" >> log
  INSTALL_PREFIX="$RUVM/packages/rust-$version"
  echo "Install Prefix : $INSTALL_PREFIX" >> log

  if [ -d "$INSTALL_PREFIX" ]; then
    echo "rust-$version is already installed!" >> log
    Error "rust-$version is already installed!"
  fi
  if [ ! -d "$PACKAGE_DIR" ]; then
    echo "$PACKAGE_DIR Does not exist!" >> log
    Error "$PACKAGE_DIR Does not exist!"
  fi
  # Test if we can download rust from url
  Log "Installing rust-$version..."
  Log "Downloading from $PACKAGE_URL..."
  curl -L# $PACKAGE_URL --output rust-$version.tar.gz
  Log "Downloading sha256..."
  curl -# $SHA_URL --output rust-$version.sha
  Log "Checking sha256..."
  FILE_SHA="$(shasum -a 256 rust-$version.tar.gz)"
  DOWNLOADED_SHA=$(cat rust-$version.sha)
  PATTERN="rust-$version.tar.gz"
  FILE_SHA=${FILE_SHA/$PATTERN}
  if [[ "$DOWNLOADED_SHA" =~ "$FILE_SHA" ]]; then
    Log "Sha256 is correct!"
  else
    Log "Sha256 is incorrect"
    echo "You should remove : "
    echo "rust-$version.tar.gz"
    echo "rust-$version.sha"
    exit 1
  fi
  Log "Untarring..."
  echo "Tar : " >> log
  tar -xvf rust-$version.tar.gz &>log
  echo "Done!" >> log
  Log "Installing..."
  cd rust-$version-$ARCH-$OSTYPE
  echo "CWD : rust-$version-$ARCH-$OSTYPE" >> log
  echo "sh install.sh --prefix=$RUVM/packages/rust-$version" >> log
  sh install.sh --prefix=$RUVM/packages/rust-$version &>log
  if [[ $? == 1 ]]; then
    Error "Could not install rust-$version please check the file named 'log'"
  fi
  echo "Adding source script for use-shell command" >> log
  touch $PACKAGE_DIR/rust-$version/source.sh
  echo "Writting 'export PATH=$PACKAGE_DIR/rust-$version/bin:$PATH'" >> log
  echo "export PATH=$PACKAGE_DIR/rust-$version/bin:$PATH" >> $PACKAGE_DIR/rust-$version/source.sh
  cd $RUVM
  rm rust-$version.tar.gz &>/dev/null
  rm -rf rust-$version-$ARCH-$OSTYPE &>/dev/null
  rm rust-$version.sha &>/dev/null
  Log "Rust-$version Installed!"
  echo "To use this version run"
  echo "ruvm use $version"
fi
if [[ $1 == "use" ]]; then
  version=$2
  if [[ ! -d "$RUVM/packages/rust-$version" ]]; then
    echo "You do not have rust $version installed!"
    echo "You can install it like this"
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
  if [[ -f "$RUVM/current" ]]; then
    rm $RUVM/current
  fi
  echo "$version" >> $RUVM/current
fi
if [[ $1 == "use-shell" ]]; then
  version=$2
  if [[ ! -d "$RUVM/packages/rust-$version" ]]; then
    echo "You do not have rust $version installed!"
    echo "You can install it like this"
    echo "ruvm install $version"
    exit 1
  fi
  Log "Setting rust-$version as default for the current session..."
  echo "Please run : "
  echo "source $RUVM/packages/rust-$version/source.sh"
fi
if [[ $1 == "list" ]]; then
  echo "Installed Versions of rust : "
  ls $RUVM/packages
  echo "Using : "
  using=$(cat $RUVM/current &>/dev/null)
  if [[ ! -f "$RUVM/current" ]]; then
    echo "No using any version of rust!"
  else
    echo "rust-$using"
  fi
fi
if [[ $1 == "remove" ]]; then
  version=$2
  if [[ ! -d "$RUVM/packages/rust-$version" ]]; then
    Error "rust-$version is not installed or does not exist!"
  fi
  Log "Removing rust-$version..."
  current=$(GetCurrent)
  if [[ $current == "$version" ]]; then
    Log "Delinking current version because it must not be linked!"
    Delink &>/dev/null
    Log "Delinked rust-$version"
  fi
  Log "Removing $RUVM/packages/rust-$version..."
  rm -rf $RUVM/packages/rust-$version
  if [[ -d "$RUVM/packages/rust-$version" ]]; then
    Error "Failed to remove $RUVM/packages/rust-$version!"
    exit 1
  fi
fi
if [[ $1 == "delink" ]]; then
  # Run Delink function
  Delink
  rm $RUVM/current
fi
