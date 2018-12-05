# **Gentoo Auto Install Script**

## **TABLE OF CONTENTS**
1. *INTRODUCTION*
    1. *GOAL*
    2. *TARGET AUDIENCE*
2. *SETUP PARAMETERS*
    1. *ARCHITECTURE*
    2. *BOOT SYSTEM*
    3. *INIT SYSTEM*
    4. *PARTITIONING*
3. *INSTALL STEPS*
    1. *SETUP STAGE*
    2. *INSTALL STAGE 1 - NETWORKING*
    3. *INSTALL STAGE 2 - PARTITIONING*
    4. *INSTALL STAGE 3 - CONFIGURATION FILE EDITS*
    5. *INSTALL STAGE 3 - BOOTSTRAPPING*
    6. *INSTALL STAGE 4 - VERIFYING BOOTSTRAP*
    7. *INSTALL STAGE 5 - *
    8. *INSTALL STAGE N - *
4. *INSTALLED PACKAGES*
    1. *ESSENTIAL*
    2. *OPTIONAL*
5. *CONTACT*

## **1 - INTRODUCTION**
### **1.1 - GOAL**
The goal of this project is to create a series of install scripts that will install a fully-functional
Gentoo distribution with an initial setup stage followed by a fully automated install based on the
parameters selected in the setup stage.

### **1.2 - TARGET AUDIENCE**
The target are Linux users that would like to use Gentoo for it's many benefits but are reluctant and/or
unwilling to go through the laborious and lengthy setup procedure manually. 
This script will not reduce the setup *time* but will reduce the amount of manual installation and 
configuration along the way.

## **2 - SETUP PARAMETERS**
### **2.1 - ARCHITECTURE**
This install will be for the x86_64 architecture. It will not work on x86 machines.

### **2.2 - BOOT SYSTEM**
This install will boot the installer under UEFI and will install it for this as well. It does not
offer options to install under BIOS and booting the installer under BIOS will result in a failed install.

### **2.3 - INIT SYSTEM**
This install will switch the init system from the default *OpenRC* to the more common *SystemD* to
allow users more familiar with this init system to manage their Gentoo installation.

### **2.4 - PARTITIONING**
This install will use a single disk partition either on a disk that has either sufficient free
space or that is empty entirely. 
1 Parition will be created, using a GPT disklabel. If the disk is not initialized with a GPT
disklabel it cannot be used for this installation.

See: **INFO/Paritions** for more information

## **3 - INSTALL STEPS**
### **3.1**
### **3.2**
### **3.3**
### **3.4**
### **3.5**
### **3.6**
### **3.7**
### **3.8**

## **4 - INSTALLED PACKAGES**
### **4.1 - ESSENTIAL**

### **4.2 - OPTIONAL**

## **5 - CONTACT**
**Maintainer:** Undomyr
**Email:** zubriket@gmail.com