# RUVM
A Simple lightweight Rust Version Manager written in bash

## Installation

With curl
```
curl -fsSL https://raw.githubusercontent.com/Interfiber/RUVM/master/tools/install | bash
```
With wget
```
wget -qO- https://raw.githubusercontent.com/Interfiber/RUVM/master/tools/install | bash
```

## Usage

Installing a new version of rust :
```
ruvm install [version]
```
Using that version of rust :
```
ruvm use [version]
```
Removing that version :
```
ruvm remove [version]
```
Updating ruvm :
```
ruvm update
```
