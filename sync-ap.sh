#!/bin/bash

#Constants for printing
SWITCH="\033["
NORMAL="${SWITCH}0m"
HEADER="${SWITCH}1;36m"
WARNING="${SWITCH}1;33m"
FAILURE="${SWITCH}1;31m"
SUCCESS="${SWITCH}1;32m"
EXTERNAL="${SWITCH}1;35m"

fn_sign () {
	echo -e "${HEADER}AM (aka carelle): bye bye ;)"
}

fn_helper () {
cat << EOF
usage: repo.sync [OPTION]... DIRECTORY... 
Sync a Git repository for a DIRECTORY (one or more) representing a git repository where is activated a Git Flow branching model.
Options:
--noPushOnMasterBranch        Skip git push on production branch
--noPushTagsOnMasterBranch    Skip git push tags on production branch
--noPullOnMasterBranch        Skip git pull of production branch from remote.
--noPushOnDev       		Skip git push on develop branch
--noPushTagsOnDev   		Skip git push tags on develop branch
--noPushTagsOnDev       	Skip git pull of develop branch from remote.
--mergeProdInDev  			Make a merge from production branch into develop branch (Warning: this breaks git-flow branching model).
--help                  	Display this help and exit
EOF
}

fn_header () {
	echo -e "${NORMAL}****************************************************************************"
	echo -e "   *************************** ${HEADER}REPO SYNC ${NORMAL}****************************"
	echo "****************************************************************************"
	echo "  Just a simple script to sync production and develop branches for a classic "
	echo -e "                        ${WARNING}Git Flow Branching Model${NORMAL}"
	echo "****************************************************************************"
	echo ""
	echo -e "Repo: ${HEADER}$2${NORMAL}"
	echo -e "Working directory:${HEADER} $1${NORMAL}"
	echo ""
	echo "****************************************************************************"
	echo "****************************************************************************"
	echo ""
}


fn_getmasterBranch () {
	
	prod=`git branch | grep main` #Priority to main branch (words matter!)
	
	if [ -z "$prod" ]; then
		prod=`git branch | grep master`
	fi	
	
	if [ -z "$prod" ]; then
		echo ""
		return 1
	fi
	
	echo "${prod//[\* ]/}" 

	return 0	
}

fn_checkProductionBranch () {
	
	if [ -z "$productionBranch" ]; then	
		productionBranch="$(fn_getProductionBranch)"
	fi
	
	if [ -z "$productionBranch" ]; then	
		return 1
	fi

	return 0
}

fn_checkDevelopmentBranch () {
	
	dev=`git branch | grep develop` 
	
	if [ -z "$dev" ]; then	
		return 1
	fi
	
	return 0
}

#Config option variables
productionBranch=""
mergeProdInDev=false
noPushOnProdBranch=false
noPushTagsOnProdBranch=false
noPullOnProdBranch=false

noPushOnDev=false
noPushTagsOnDev=false
noPushTagsOnDev=false
helpMode=false
directories=""


#Option manager
fn_optionManger () {
	if [ $1 == "--noPushOnProdBranch" ]; then
		noPushOnProdBranch=true
	elif [ $1 == "--noPushTagsOnProdBranch" ]; then
		noPushTagsOnProdBranch=true		
	elif [ $1 == "--noPullOnProdBranch" ]; then
		noPullOnProdBranch=true
	elif [ $1 == "--noPushOnDev" ]; then
		noPushOnDev=true
	elif [ $1 == "--noPushTagsOnDev" ]; then
		noPushTagsOnDev=true				
	elif [ $1 == "--noPushTagsOnDev" ]; then
		noPushTagsOnDev=true		
	elif [ $1 == "--mergeProdInDev" ]; then
		mergeProdInDev=true			
	elif [ $1 == "--help" ]; then
		helpMode=true	
	elif [ $1 != "--*" ]; then
		directories=$directories$1","
	fi
}

home=$(pwd)

# Parameters analisys.
for param in "$@"
do
	fn_optionManger $param
done

# Check help mode.
if $helpMode; then
	fn_helper
	fn_sign
	exit;
fi

if [ -z "$directories" ]; then
	directories="."
fi

# Cycling on direcotories provided.
IFS=,
for repo in $directories; do
	fn_header $home $repo

	if [ -d "$repo" ]; then

		echo -e "${HEADER}Info: ${NORMAL}Directory: ${SUCCESS}Ok!${NORMAL}"   	
		
		cd $repo
		
		isGitRepo=false

		if [ -d .git ]; then
		cd .git
		if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == "true" ]; then
			isGitRepo=true
		fi
		cd ..
		fi;	
		
		if $isGitRepo; then
			echo -e "${HEADER}Info:${NORMAL} Git repo:${SUCCESS} Ok!${NORMAL}"											
			
			if ! fn_checkProductionBranch; then
				echo -e "${WARNING}Warning: ${FAILURE}Production (main/master) branch not defined!!${NORMAL}"
				exit 1;
			fi			
			
			if ! fn_checkDevelopmentBranch; then
				echo -e "${WARNING}Warning: ${FAILURE}Develop branch not defined!!${NORMAL}"
				exit 1;
			fi			

			
			echo -e "${HEADER}Info:${NORMAL} Production  Branch:${HEADER} $productionBranch${NORMAL}"	
			echo -e "${HEADER}Info:${NORMAL} Development Branch:${HEADER} develop${NORMAL}"	
					

			echo ""   
			echo -e "${HEADER}Info: ${NORMAL}Starting git commands...${NORMAL}"   
			echo ""   	
			echo -e "${EXTERNAL}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> GIT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${HEADER}"	
			echo ""   	
			echo -e "${HEADER}Info: ${NORMAL}Syncronizing ${HEADER}develop${NORMAL} branch...${EXTERNAL}"
			echo ""   	
			git checkout develop

			if $mergeProdInDev; then
				git merge $productionBranch
			fi

			if ! $noPushTagsOnDev; then
				git pull origin develop
			else
				echo -e "${HEADER}Info:${WARNING} Skipped pull of develop branch!${NORMAL}"
			fi
			
			if ! $noPushOnDev; then
				git push origin develop
			else
				echo -e "${HEADER}Info:${WARNING} Skipped push of develop to the origin!${NORMAL}"
			fi
			
			if ! $noPushTagsOnDev; then
				git push --tags
			else
				echo -e "${HEADER}Info:${WARNING} Skipped push of tags of develop to the origin!${NORMAL}"
			fi

			echo ""   	
			echo -e "${HEADER}Info: ${NORMAL}Syncronizing ${HEADER}${productionBranch}${NORMAL} branch...${EXTERNAL}"
			echo ""   	
			git checkout $productionBranch

			if ! $noPullOnProdBranch; then
				git pull origin $productionBranch
			else
				echo -e "${HEADER}Info:${WARNING} Skipped pull of ${productionBranch} branch!${NORMAL}"
			fi
			
			if ! $noPushOnProdBranch; then
				git push origin $productionBranch
			else
				echo -e "${HEADER}Info:${WARNING} Skipped push of ${productionBranch} to the origin!${NORMAL}"
			fi
					
			if ! $noPushTagsOnProdBranch; then
				git push --tags
			else
				echo -e "${HEADER}Info:${WARNING} Skipped push of tags of ${master} to the origin!${NORMAL}"
			fi

			echo ""   	
			echo -e "${HEADER}Info: ${NORMAL}Coming back to ${HEADER}develop${NORMAL} branch...${EXTERNAL}"
			echo ""   	
			git checkout develop
			echo -e "${EXTERNAL}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< GIT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${HEADER}"	
			echo ""

			cd $home

		else
			echo -e "${WARNING}Warning: ${FAILURE} Git repo:KO!${NORMAL} Probably you didn't provide the root directory of your Git repo."
		fi					

	else
		echo ""
		echo -e "${WARNING}Warning: ${FAILURE}Directory not valid!${NORMAL}"
		echo ""
	fi
done

echo ""
fn_sign

exit;